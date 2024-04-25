#!/bin/bash
#
# Copyright (c) 2024 Andreas Schnederle-Wagner
# Futureweb GmbH
# https://www.futureweb.at
#
# fix for: https://talk.plesk.com/threads/issues-with-ssl-certificate-renewal-for-mail-services-in-plesk-seeking-automated-solution-via-cli-or-api.374148/
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

# Loop through mail domains
for domain in $($PLESK_BIN bin domain --list | grep '^mail\.\|^[^.]*$'); do
    # Trim "mail." prefix if it exists
    domain_without_prefix="${domain#mail.}"

    # Get the SSL/TLS certificate for mail for the current domain
    mail_certificate=$($PLESK_BIN bin subscription_settings --info $domain_without_prefix | grep -oP 'SSL/TLS certificate for mail:\s*\K.*')

    # Print the mail certificate
    #echo "Mail certificate: $mail_certificate"

    if [[ "$mail_certificate" == "Lets Encrypt $domain" ]]; then
        echo "Renew & Re-Assign Cert for $domain_without_prefix Mail Services with Cert: $mail_certificate"
        $PLESK_BIN bin certificate --update "$mail_certificate" -domain $domain
        $PLESK_BIN bin subscription_settings --update $domain_without_prefix -mail_certificate "mail_certificate"
    else
        echo "Mail certificate is not 'Lets Encrypt for $domain_without_prefix'"
    fi
done
