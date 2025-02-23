#!/bin/bash
/docker_compose/scripts/backup_and_cleanup.sh \
--destination /home/denny/OneDrive/Backups/VaultWarden/backups_daily/ \ 
--overwrite no \
--keep 5 \
/docker_compose/vaultwarden/Data/Vaultwarden/attachments \ 
/docker_compose/vaultwarden/Data/Vaultwarden/config.json \
/docker_compose/vaultwarden/Data/Vaultwarden/db.sqlite3 \
/docker_compose/vaultwarden/Data/Vaultwarden/rsa_key.pem