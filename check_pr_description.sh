#!/bin/bash

check_pr_description() {
    local pr_description="$1"
    local jira_ticket="$2"

    if [[ -z "$pr_description" || "$pr_description" == "null" ]]; then
        echo "PR description is not provided."
        exit 1
    fi

    if [[ "$pr_description" =~ ^Description[[:space:]]+(.+)[[:space:]]+JIRA\ Ticket\ Link:\ ([A-Za-z]+-[0-9]+) ]]; then
        description="${BASH_REMATCH[1]}"
        jira_ticket_desc="${BASH_REMATCH[2]}"
        jira_ticket_desc_uppercase=$(echo "$jira_ticket_desc" | awk '{print toupper($0)}')
        echo "PR description contains JIRA ticket reference: $jira_ticket_desc_uppercase"
        if [[ "$jira_ticket" != "$jira_ticket_desc_uppercase" ]]; then
            echo "JIRA ticket reference in title ($jira_ticket) does not match the one in description ($jira_ticket_desc_uppercase)."
            exit 1
        fi
    else
        echo "PR description does not contain the required format."
        exit 1
    fi

    if [[ "$pr_description" =~ ^Description[[:space:]]+[^[:space:]] ]]; then
        echo "PR description includes a brief description."
    else
        echo "PR description must contain a brief description starting with 'Description'."
        exit 1
    fi
}

check_pr_description "$1" "$2"
