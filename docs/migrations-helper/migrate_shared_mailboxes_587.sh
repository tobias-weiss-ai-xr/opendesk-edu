#!/bin/bash
# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0

while IFS=',' read -r context_id user_id account_id primary_address name login password \
  personal reply_to mail_server_URL mail_starttls transport_login transport_password \
  transport_server_URL transport_starttls archive_fullname drafts_fullname sent_fullname \
  spam_fullname trash_fullname confirmed_spam_fullname confirmed_ham_fullname; do

  echo "Processing $name ($primary_address)"

  updatesecondaryaccount \
    -A "$MASTER_ADMIN_USER" -P "$MASTER_ADMIN_PW" \
    -e "$primary_address" \
    -c "$context_id" \
    --users "$user_id" \
    --login "$login" \
    --password "$password" \
    --name "$name" \
    --personal "$personal" \
    --reply-to "$reply_to" \
    --mail-server dovecot \
    --mail-port 143 \
    --mail-protocol imap \
    --transport-server postfix-ox \
    --transport-port 587 \
    --transport-protocol smtp

done < <(
  listsecondaryaccount -c 1 -A "$MASTER_ADMIN_USER" -P "$MASTER_ADMIN_PW" --csv \
  | tail -n +2 \
  | grep ':25' \
  | sed 's/^"//; s/"$//; s/","/,/g'
)
