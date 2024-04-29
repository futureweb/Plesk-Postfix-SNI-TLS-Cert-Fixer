#!/bin/bash
#
# Copyright (c) 2024 Andreas Schnederle-Wagner
# Futureweb GmbH
# https://www.futureweb.at
#
# Latest Version: https://github.com/futureweb/Plesk-Postfix-SNI-TLS-Cert-Fixer/
# Fix for: https://talk.plesk.com/threads/issues-with-ssl-certificate-renewal-for-mail-services-in-plesk-seeking-automated-solution-via-cli-or-api.374148/
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

PLESK_BIN="/usr/sbin/plesk"

# Initialize counters for statistics
total_domains=0
renewed_domains=0
errors=0

# Function to print error message and increment error count
print_error() {
    echo "Error: $1"
    ((errors++))
}

# Loop through mail domains
while IFS= read -r domain; do
    ((total_domains++))

    # Trim "mail." prefix if it exists
    domain_without_prefix="${domain#mail.}"

    # Get the SSL/TLS certificate for mail for the current domain
    mail_certificate=$("$PLESK_BIN" bin subscription_settings --info "$domain_without_prefix" | grep -oP 'SSL/TLS certificate for mail:\s*\K.*')

    if [[ -z "$mail_certificate" ]]; then
        print_error "Failed to retrieve SSL/TLS certificate for $domain_without_prefix"
        continue
    fi

    if [[ "$mail_certificate" == "Lets Encrypt $domain" ]]; then
        echo "Renew & Re-Assign Cert for $domain_without_prefix Mail Services with Cert: $mail_certificate"
        if ! "$PLESK_BIN" bin certificate --update "$mail_certificate" -domain "$domain"; then
            print_error "Failed to renew certificate for $domain_without_prefix"
            continue
        fi

        if ! "$PLESK_BIN" bin subscription_settings --update "$domain_without_prefix" -mail_certificate "$mail_certificate"; then
            print_error "Failed to update mail certificate for $domain_without_prefix"
            continue
        fi

        ((renewed_domains++))
    else
        echo "Mail certificate is not 'Lets Encrypt for $domain_without_prefix'"
    fi
done < <("$PLESK_BIN" bin domain --list | grep '^mail\.\|^[^.]*$')

# Print run statistics
echo "Script finished processing $total_domains domains."
echo "$renewed_domains domains had their certificates renewed."
echo "$errors errors occurred during script execution."

# Restart Postfix
echo "Restarting Postfix..."
if /usr/sbin/service postfix restart; then
    echo "Postfix restarted successfully."
else
    print_error "Failed to restart Postfix."
fi
