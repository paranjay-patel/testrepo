#!/bin/bash

# Function to check if PR title contains a JIRA ticket reference (case-insensitive)
check_jira_ticket_reference() {
    local pr_title="$1"
    if [[ "$pr_title" =~ ^([A-Z]+-[0-9]+):\ (.+)$ ]]; then
        jira_ticket="${BASH_REMATCH[1]}"
        title_message="${BASH_REMATCH[2]}"
        jira_ticket_uppercase=$(echo "$jira_ticket" | awk '{print toupper($0)}')
        echo "PR title contains JIRA ticket reference: $jira_ticket_uppercase"
        echo "PR title message: $title_message"
    else
        echo "PR title does not contain a proper JIRA ticket reference. please add a JIRA ticket reference in proper format. ex. HT-211: Modified info.txt "
        exit 1
    fi
}

# Function to verify that all commits are signed
check_commits_signed() {
    local pr_number="$1"
    local repo="$2"
    local commits=$(gh pr view "$pr_number" --repo "$repo" --json commits --jq '.commits[].oid')

    for commit in $commits; do
        local commit_info=$(gh api repos/$repo/git/commits/$commit)
        local verification_status=$(echo "$commit_info" | jq -r '.verification.verified')
        local commit_message=$(echo "$commit_info" | jq -r '.message')
        local commit_author=$(echo "$commit_info" | jq -r '.author.name')
        local commit_date=$(echo "$commit_info" | jq -r '.author.date')

        if [[ "$verification_status" != "true" ]]; then
            echo "Commit $commit is not signed."
            echo "  Commit message: $commit_message"
            echo "  Author: $commit_author"
            echo "  Date: $commit_date"
            exit 1
        else
            echo "Commit $commit is signed."
            echo "  Commit message: $commit_message"
            echo "  Author: $commit_author"
            echo "  Date: $commit_date"
        fi
    done
    echo "All commits are signed."
}

# Function to check if PR description is provided and contains the JIRA ticket reference
check_pr_description() {
    local pr_description="$1"
    local jira_ticket="${2}"

    # Check if the description is provided
    if [[ -z "$pr_description" || "$pr_description" == "null" ]]; then
        echo "PR description is not provided."
        exit 1
    fi

    # Check for JIRA ticket link format and existence
    if [[ "$pr_description" =~ ^Description[[:space:]]+(.+)[[:space:]]+JIRA\ Ticket\ Link:\ ([A-Za-z]+-[0-9]+) ]]; then
        description="${BASH_REMATCH[1]}"
        jira_ticket_desc="${BASH_REMATCH[2]}"
        jira_ticket_desc_uppercase=$(echo "$jira_ticket_desc" | awk '{print toupper($0)}')
        echo "PR description contains JIRA ticket reference: $jira_ticket_desc_uppercase"
        if [[ "$jira_ticket_uppercase" != "$jira_ticket_desc_uppercase" ]]; then
            echo "JIRA ticket reference in title ($jira_ticket_uppercase) does not match the one in description ($jira_ticket_desc_uppercase)."
            exit 1
        fi
    else
        echo "PR description does not contain the required format."
        exit 1
    fi

    # Ensure the description contains a brief summary
    if [[ "$pr_description" =~ ^Description[[:space:]]+[^[:space:]] ]]; then
        echo "PR description includes a brief description."
    else
        echo "PR description must contain a brief description starting with 'Description'."
        exit 1
    fi
}

# Get PR details
PR_NUMBER=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
PR_TITLE=$(jq --raw-output .pull_request.title "$GITHUB_EVENT_PATH")
PR_DESCRIPTION=$(jq --raw-output .pull_request.body "$GITHUB_EVENT_PATH")
REPO_FULL_NAME=$(jq --raw-output .repository.full_name "$GITHUB_EVENT_PATH")

# Log PR details
echo "PR Number: $PR_NUMBER"
echo "PR Title: $PR_TITLE"
echo "Repository: $REPO_FULL_NAME"
echo "PR Description: $PR_DESCRIPTION"

# Perform checks
check_jira_ticket_reference "$PR_TITLE"
check_commits_signed "$PR_NUMBER" "$REPO_FULL_NAME"
check_pr_description "$PR_DESCRIPTION"

# Output status report
echo "PR validation checks completed successfully."
