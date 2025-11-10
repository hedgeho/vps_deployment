#!/bin/bash

REPO_DIR="/path/to/vps_deployment"
LOG_FILE="$REPO_DIR/update.log"

cd "$REPO_DIR" || exit 1

echo "$(date): Checking for updates..." >> "$LOG_FILE"

git fetch origin master

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/master)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "$(date): Changes detected, updating..." >> "$LOG_FILE"

    git pull origin master >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        echo "$(date): Git pull successful, validating configuration..." >> "$LOG_FILE"

        docker compose config > /dev/null 2>> "$LOG_FILE"
        if [ $? -ne 0 ]; then
            echo "$(date): ERROR - docker-compose validation failed, rolling back" >> "$LOG_FILE"
            git reset --hard HEAD~1
            exit 1
        fi

        echo "$(date): Configuration validated, restarting services..." >> "$LOG_FILE"
        docker compose up -d --force-recreate >> "$LOG_FILE" 2>&1
        echo "$(date): Deployment updated successfully" >> "$LOG_FILE"
    else
        echo "$(date): Git pull failed" >> "$LOG_FILE"
        exit 1
    fi
else
    echo "$(date): No changes detected" >> "$LOG_FILE"
fi