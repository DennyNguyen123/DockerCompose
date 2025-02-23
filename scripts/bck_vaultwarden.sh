#!/bin/bash
/docker_compose/scripts/backup_and_cleanup.sh \
--destination /home/denny/OneDrive/Backups/VaultWarden/backups_daily/ \ 
--overwrite no \
--keep 5 \
/docker_compose/vaultwarden/Data/attachments \ 
/docker_compose/vaultwarden/Data/config.json \
/docker_compose/vaultwarden/Data/db.sqlite3 \
/docker_compose/vaultwarden/Data/rsa_key.pem