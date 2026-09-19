#!/bin/sh
set -eu

mkdir -p /run/sshd /var/spool/cron/crontabs
touch /var/log/auth.log
chown syslog:adm /var/log/auth.log
chmod 0640 /var/log/auth.log
rsyslogd
cron

# The named volume retains client.keys across ordinary container recreation.
if [ ! -s /var/ossec/etc/client.keys ]; then
  attempt=0
  until /var/ossec/bin/agent-auth -m wazuh.manager -A DISPATCH-WKS-04; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 30 ]; then
      echo 'Wazuh agent enrollment failed after 30 attempts' >&2
      exit 1
    fi
    sleep 5
  done
fi

/var/ossec/bin/wazuh-control start
exec /usr/sbin/sshd -D
