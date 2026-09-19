# Attack simulation: one three-stage exercise

Run only against the target in this self-owned Compose lab. Commands below assume you are in the repository root and have completed `./scripts/setup.sh`. Wait until `DISPATCH-WKS-04` is **Active** under **Wazuh → Agents**. Use the dashboard's **Threat hunting** or **Security events** view, filter by `agent.name: DISPATCH-WKS-04`, and set the time range to include your run. UI labels vary slightly by Wazuh release.

Save the attacker's container IP for your report:

```sh
./scripts/lab.sh exec -T attacker hostname -i
```

## 1. Recon — T1595 Active Scanning

```sh
./scripts/lab.sh exec -T attacker nmap -sT -sV --version-all -p 22 --open dispatch-wks-04
```

**Dashboard check:** Look for rule `100100` and an `sshd` message containing `kex_exchange_identification: Connection closed by remote host`. Save the Nmap terminal output too. This rule reports an SSH key-exchange artifact, so a clean scan result without the alert is a visibility gap to record, not proof that scanning did not occur. The endpoint agent does not collect all network probe traffic; corroborate the attacker's IP with the adjacent target `/var/log/auth.log` connection line.

## 2. Brute force — T1110 Brute Force

The three passwords are intentionally small and lab-specific; the correct password is last. Hydra stops after the first success.

```sh
./scripts/lab.sh exec -T attacker sh -c 'printf "%s\n" "Spring2026!" "Logistics123!" "Dispatch123!" > /tmp/dispatch-passwords.txt && hydra -l dispatch01 -P /tmp/dispatch-passwords.txt -t 2 -f -V ssh://dispatch-wks-04'
```

**Dashboard check:** Filter by `agent.name: DISPATCH-WKS-04`, `sshd` and the attacker's IP. Inspect failed-password alerts followed by a successful login for `dispatch01`; record the actual Wazuh rule IDs, timestamps and raw log text. Hydra's reported success is a separate source of evidence. If a success alert is delayed, widen the dashboard time range and check `/var/log/auth.log` on the target with `./scripts/lab.sh exec -T dispatch-wks-04 tail -n 80 /var/log/auth.log`.

## 3. Persistence — T1053.003 Cron

This uses the compromised account to add a recurring **local syslog marker**. It has no network callback and no payload beyond the cron simulation. SSH prompts for `Dispatch123!`.

```sh
./scripts/lab.sh exec attacker ssh -o StrictHostKeyChecking=accept-new dispatch01@dispatch-wks-04 'printf "%s\n" "* * * * * /usr/bin/logger -t nordfracht-lab simulated-callback-no-network" | crontab -; crontab -l'
```

**Dashboard check:** Look for a file integrity event on `/var/spool/cron/crontabs/dispatch01` after the SSH login. Record its rule ID and timestamp; the exact rule ID depends on Wazuh's rule set. Verify the installed entry using `./scripts/lab.sh exec -T dispatch-wks-04 crontab -u dispatch01 -l`. The marker will appear in `/var/log/syslog` after about a minute; it does not contact a remote address.

## Capture, document, clean up

The repository includes screenshots and an incident report from the observed 19 September 2026 run. For a repeat run, save your own screenshots in `evidence/` and make a copy of `docs/incident-report.md` with your own timestamps, IPs and rule IDs. If an expected alert is absent, state that in the report instead of inventing evidence.

To remove the simulated persistence while keeping the lab running:

```sh
./scripts/lab.sh exec -T dispatch-wks-04 crontab -u dispatch01 -r
```
