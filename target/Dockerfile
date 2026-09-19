FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg openssh-server cron rsyslog \
    && install -m 0755 -d /usr/share/keyrings \
    && curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH \
       | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main' \
       > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && WAZUH_MANAGER=wazuh.manager WAZUH_AGENT_NAME=DISPATCH-WKS-04 \
       apt-get install -y --no-install-recommends wazuh-agent=4.14.7-1 \
    && useradd -m -s /bin/bash dispatch01 \
    && echo 'dispatch01:Dispatch123!' | chpasswd \
    && printf '%s\n' 'PasswordAuthentication yes' 'LogLevel VERBOSE' \
       > /etc/ssh/sshd_config.d/10-nordfracht-lab.conf \
    && mkdir -p /run/sshd /var/log \
    && printf '\n<ossec_config>\n  <localfile>\n    <log_format>syslog</log_format>\n    <location>/var/log/auth.log</location>\n  </localfile>\n  <syscheck>\n    <disabled>no</disabled>\n    <directories realtime="yes" check_all="yes">/var/spool/cron/crontabs</directories>\n  </syscheck>\n</ossec_config>\n' >> /var/ossec/etc/ossec.conf \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
