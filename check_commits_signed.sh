#!/bin/bash

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

check_commits_signed "$1" "$2"
