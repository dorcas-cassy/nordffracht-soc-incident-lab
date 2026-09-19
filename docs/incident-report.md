# NordFracht Logistics — SOC incident report

| Case detail | Value |
| --- | --- |
| Case | NF-SOC-001 |
| Environment | Isolated, self-owned Docker exercise |
| Affected asset | `DISPATCH-WKS-04`, dispatch department (`172.18.0.4`) |
| Observed window | 19 September 2026, 17:47:32–17:47:54 UTC |
| Status | Detection verified; simulated cron removed and lab stopped |

## Executive summary

In this controlled exercise, an attacker scanned the SSH service on a dispatch workstation, tried three passwords for the `dispatch01` account, and signed in using the deliberately weak lab password. The attacker then installed a scheduled task that writes a harmless local log marker once per minute. Wazuh recorded evidence for each stage: an SSH pre-authentication event, failed and successful logins, and a new crontab file. This demonstrates how a reachable SSH service and weak credentials can lead to unauthorized access and a recurring task. The supplied commands did not access freight records or send data outside the lab. After evidence collection, the scheduled task was removed and the lab was stopped. Password rotation and SSH restrictions remain recommendations for a real deployment.

## Scope and evidence

The attacker container (`172.18.0.6`) and Ubuntu target (`172.18.0.4`) shared only the local Compose network. The analyst correlated Nmap and Hydra terminal output with `/var/log/auth.log`, Wazuh SSH alerts, and Wazuh file integrity monitoring (FIM). Dashboard screenshots are saved as [recon](../evidence/wazuh-recon.png), [SSH authentication](../evidence/wazuh-ssh-auth.png), and [cron file details](../evidence/wazuh-cron-fim.png). All times below are UTC; the screenshots show Berlin local time (UTC+2).

## Technical timeline

| Time (UTC, 19 Sep 2026) | Event | Evidence / Wazuh rule |
| --- | --- | --- |
| 17:47:32.830 | The attacker scanned TCP/22 on `172.18.0.4` with Nmap. It found OpenSSH 9.6p1. | Nmap output and SSH key-exchange-close alert, rule `100100`. The alert itself does not contain the source IP; the adjacent target SSH connection log identifies `172.18.0.6`. |
| 17:47:40.886–17:47:42.845 | Hydra tried a three-password list for `dispatch01`; two guesses failed. | Hydra output; PAM failure rule `5503` and SSH failed-password rule `5760`, both associated with `172.18.0.6`. |
| 17:47:44.847 | `dispatch01` authenticated over SSH from `172.18.0.6`. | Hydra success output and Wazuh SSH authentication-success rule `5715`. |
| 17:47:54.300 | A user crontab was created for `dispatch01`. | Wazuh FIM file-added rule `554` on `/var/spool/cron/crontabs/dispatch01`. A second SSH login used to install the task produced rule `5715` at 17:47:54.854. |

## Indicators and artifacts

| Indicator / artifact | Observed value | Analyst interpretation |
| --- | --- | --- |
| Source container IP | `172.18.0.6` | Lab attacker address in SSH failures and success; correlate the recon event with the adjacent connection log. |
| Target container IP | `172.18.0.4` | Dispatch workstation in the Compose network. |
| Account | `dispatch01` | Deliberately weak lab account used for SSH. |
| Persistence location | `/var/spool/cron/crontabs/dispatch01` | New user crontab detected by FIM. |
| Scheduled command | `/usr/bin/logger -t nordfracht-lab simulated-callback-no-network` | Local log marker only; no remote endpoint or callback. |

## Root cause

The lab deliberately allowed password authentication to a reachable SSH service and assigned `dispatch01` a weak, known password. The three-entry password trial found that password, allowing user-level SSH access. The account could then create its own cron task. These are exercise conditions, not claims about a real NordFracht environment.

## Business impact

The observed impact is access to one simulated dispatch account and creation of a recurring local task. The supplied exercise did not access shipment data, customer records, other hosts, or an external network destination. In a real logistics environment, a similar uncontained account compromise could disrupt dispatch operations or expose shipment information; this lab does not establish that such damage occurred.

## Analyst assessment and detection limits

The sequence is supported by independent attacker command output and endpoint alerts. Rule `100100` detects an SSH key-exchange close, which is consistent with the Nmap service probe but does not, by itself, prove a scan or identify its source. The two failed-password alerts followed by rule `5715` and the FIM rule `554` establish the login and crontab creation. The installed command was verified with `crontab -u dispatch01 -l` before cleanup.

## Containment and remediation

1. **Completed in the lab:** Remove the simulated `dispatch01` crontab. The verification command returned `no crontab for dispatch01`.
2. Rotate the `dispatch01` password and inspect the account for other changes.
3. Restrict SSH to approved management sources; use key-based authentication and disable password authentication where practical.
4. Review `/var/log/auth.log` and Wazuh events from 17:47:32–17:47:54 UTC for additional activity.
5. Keep FIM on user crontabs and tune alerting for repeated SSH failures followed by successful login.

## Closure criteria

The detection exercise and lab cleanup are complete: the cron entry was removed, its absence was verified, and `./scripts/lab.sh down` stopped the containers. The intentionally weak credential remains in the lab definition so the exercise is reproducible. Password rotation, SSH restrictions, and broader account review are recommendations for a real environment, not actions claimed to have been performed here.
