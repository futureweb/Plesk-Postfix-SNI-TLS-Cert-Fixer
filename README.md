# Plesk Postfix SNI TLS Cert Fixer

This script addresses a bug encountered in Plesk regarding the assignment of SSL certificates for mail services.

## Bug Description

When a secondary domain's SSL certificate is assigned to the mail services of a primary domain in Plesk, and the secondary domain's certificate is renewed, the certificate in the Postfix hash map for the primary domain is not updated. This results in the delivery of outdated certificates for mail services.

## Bug Reproduction

To reproduce the issue, follow these steps:

1. Have a primary domain with active mail services, e.g., `example.com`.
2. Have another domain, e.g., `mail.example.com`.
3. Create an SSL certificate (Let’s Encrypt or other) for the `mail.example.com` domain using SSL.
4. Assign the `mail.example.com` certificate to the mail services of the `example.com` domain.
5. Renew the certificate for `mail.example.com`.
6. Postfix is still delivering the old Cert as it's cached within Postfix Certs Hash Map (/var/spool/postfix/plesk/certs.db).

## Solution

The provided script fixes the issue by checking whether a renewed certificate is still actively assigned to other domains/services. If so, it updates the configuration files, specifically the Postfix cert hash map, to prevent the delivery of outdated certificates when a current one exists.

## Usage

1. Clone the repository:

```bash
git clone https://github.com/futureweb/Plesk-Postfix-SNI-TLS-Cert-Fixer.git
```

2. Make the script executable:

```bash
chmod +x plesk_postfix_sni_tls_cert_fixer.sh
```

3. Execute the script:

```bash
./plesk_postfix_sni_tls_cert_fixer.sh
```

## Important Note

While this script provides a workaround for the issue, it's essential to address the underlying problem. Outdated certificates should not be delivered when they have already been renewed. The script is provided as-is, and the developer holds no responsibility for any problems arising from its use.

## Customization

Depending on your specific Plesk setup and configurations, customization of the script may be necessary to suit other scenarios.

## Cronjob Setup

To ensure that certificates are fixed in a timely manner, consider setting up a cronjob that executes the script regularly. For example, to run the script every other month, add the following cronjob:

```bash
0 0 1 */2 * /path/to/plesk_postfix_sni_tls_cert_fixer.sh
```

This will execute the script on the first day of every other month.

## Acknowledgment

This script was developed by Andreas Schnederle-Wagner, Futureweb GmbH (https://www.futureweb.at).

---

**Note:** Please ensure you have proper backups before executing any scripts, especially those that modify system configurations.
