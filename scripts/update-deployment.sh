#!/bin/bash

LOG_FILE="update.log"


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

        echo "$(date): Configuration validated, pulling images and restarting services..." >> "$LOG_FILE"
        docker compose pull >> "$LOG_FILE" 2>&1
        docker compose up -d --force-recreate >> "$LOG_FILE" 2>&1
        echo "$(date): Deployment updated successfully" >> "$LOG_FILE"
    else
        echo "$(date): Git pull failed" >> "$LOG_FILE"
        exit 1
    fi
else
    echo "$(date): No changes detected, checking for image updates..." >> "$LOG_FILE"
    docker compose pull >> "$LOG_FILE" 2>&1
    docker compose up -d >> "$LOG_FILE" 2>&1
    echo "$(date): Images updated" >> "$LOG_FILE"
fi