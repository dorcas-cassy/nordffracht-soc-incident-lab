# NordFracht Logistics — SOC incident report

**Case:** NF-SOC-001

**Environment:** Isolated, self-owned Docker exercise

**Affected asset:** DISPATCH-WKS-04, dispatch department
**Status:** Draft scenario; validate every observation after running the lab

## Executive summary

In this controlled exercise, an attacker examined the SSH service on a dispatch workstation, tried several passwords against the `dispatch01` account, and used the deliberately weak lab password to sign in. The attacker then added a scheduled task that writes a harmless local marker once per minute. The sequence models how an exposed administrative service and weak credentials could permit unauthorized access and persistence. The lab does not simulate data theft or a real external callback. The recommended response is to remove the scheduled task, reset the account password, restrict SSH access, and review the Wazuh evidence for the full sequence. This report must be finalized with the observed timestamps, IP addresses and rule IDs after the exercise.

## Scope and evidence

The affected asset is the Ubuntu container `DISPATCH-WKS-04`. The attacker is a separate container on the same Docker network. Evidence sources are Nmap and Hydra terminal output, target `/var/log/auth.log`, Wazuh SSH alerts, and Wazuh file integrity alerts for the user's crontab. Screenshots belong in `../evidence/` after the exercise.

## Technical timeline

| Time (timezone shown in dashboard) | Event | Evidence / Wazuh rule |
| --- | --- | --- |
| [RECON_TIMESTAMP] | The attacker at [ATTACKER_IP] scanned TCP/22 on [TARGET_IP]. | Nmap output; SSH pre-auth event if present, rule [RECON_RULE_ID] |
| [FIRST_FAILURE_TIMESTAMP] | `dispatch01` received failed SSH password attempts from [ATTACKER_IP]. | `/var/log/auth.log`; Wazuh rule [FAILURE_RULE_ID] |
| [SUCCESS_TIMESTAMP] | `dispatch01` authenticated from [ATTACKER_IP]. | SSH success event; Wazuh rule [SUCCESS_RULE_ID] |
| [CRON_CHANGE_TIMESTAMP] | The attacker installed a cron entry for `dispatch01`. | FIM event on `/var/spool/cron/crontabs/dispatch01`; Wazuh rule [FIM_RULE_ID] |

If a stage produced no Wazuh alert, replace its rule placeholder with `No alert observed` and explain the gap in the analyst assessment below.

## Indicators of compromise and artifacts

| Indicator / artifact | Value | Analyst interpretation |
| --- | --- | --- |
| Source container IP | [ATTACKER_IP] | Correlate across SSH failures and success; lab address only |
| Target container IP | [TARGET_IP] | Dispatch workstation in the Docker network |
| Account | `dispatch01` | Deliberately weak lab account used for SSH |
| Persistence location | `/var/spool/cron/crontabs/dispatch01` | User crontab modified after login |
| Scheduled command | `/usr/bin/logger -t nordfracht-lab simulated-callback-no-network` | Harmless local marker; no remote endpoint |

## Root cause

The lab deliberately enables password authentication on SSH and assigns `dispatch01` a weak, known password. The attacker can reach TCP/22 from the lab network. That combination permits the short password trial and subsequent interactive SSH access. The cron service then accepts a user-level scheduled task. These are exercise conditions; they are not claims about a real NordFracht environment.

## Business impact

In the simulation, the attacker obtains access to one dispatch workstation account and creates a recurring task. No freight records, customer data, payment systems or other hosts are accessed by the supplied commands. In a real logistics environment, an uncontained workstation compromise could interrupt dispatch operations or expose shipment data, but this lab does not measure such impact.

## Analyst assessment

Correlate the source IP, `dispatch01` username and event times across the three stages. The Nmap output establishes that the scan was run; the Wazuh recon rule only suggests a pre-auth SSH probe. Confirm the exact rule IDs and whether the file integrity alert arrived. Record any missing alert, dashboard delay or time-zone mismatch here before presenting this as observed analyst work.

## Containment and remediation

1. Remove the `dispatch01` crontab entry and inspect the account's other scheduled tasks.
2. Reset the `dispatch01` password and review other accounts for weak or reused passwords.
3. Restrict SSH to approved management sources; use key-based authentication and disable password authentication where practical.
4. Review `/var/log/auth.log` and Wazuh events around [FIRST_FAILURE_TIMESTAMP] through [CRON_CHANGE_TIMESTAMP] for additional logins or changes.
5. Keep Wazuh file integrity monitoring on user crontabs and tune alerting for repeated SSH failures and successful logins after failures.

## Closure criteria

The cron entry is removed, the account credential is rotated, SSH exposure is reduced, and the timeline is supported by saved event details. Mark this report final only after those checks and the bracketed fields have been completed from the actual lab run.
