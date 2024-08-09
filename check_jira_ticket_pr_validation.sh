#!/bin/bash

check_jira_ticket_reference() {
    local pr_title="$1"
    if [[ "$pr_title" =~ ^([A-Z]+-[0-9]+):\ (.+)$ ]]; then
        jira_ticket="${BASH_REMATCH[1]}"
        title_message="${BASH_REMATCH[2]}"
        jira_ticket_uppercase=$(echo "$jira_ticket" | awk '{print toupper($0)}')
        echo "PR title contains JIRA ticket reference: $jira_ticket_uppercase"
        echo "PR title message: $title_message"
    else
        echo "PR title does not contain a proper JIRA ticket reference. Please add a JIRA ticket reference in proper format. ex. HT-211: Modified info.txt"
        exit 1
    fi
}

check_jira_ticket_reference "$1"
