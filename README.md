# linux-admin-scripts

Bash automation for user management, service control and administrative diagnostics on Linux systems.

---

## Linux Administration & Bash Automation

A collection of practical Bash scripts created to support daily Linux administration tasks.
The focus of this repository is automation, service monitoring, and extraction of system information.

---

## Goals of the project

* automate recurring administrative activities
* simplify system checks
* provide structured output for further analysis
* improve reliability and speed of operational tasks

---

## Implemented topics

* user and group management
* service status verification
* system information collection
* log and process filtering
* system resource monitoring

---

## Technologies & Tools

* Bash
* systemctl
* grep
* awk
* standard GNU/Linux utilities

---

## Example use cases

* quick verification whether important services are running
* extracting relevant system data for troubleshooting
* administrative preparation before maintenance
* repetitive daily checks

---

## Repository Structure

```bash
.
├── monitoring/
├── services/
├── user_management/
├── logs/
└── README.md
```

Each script is self-contained and can be executed independently.
Most scripts require standard user permissions; some administrative checks may require elevated privileges.

---

## Example execution

Make a script executable and run it:

```bash
chmod +x script.sh
./script.sh
```

---

## Monitoring Quick Start

Make monitoring scripts executable:

```bash
chmod +x monitoring/*.sh
```

Run full system health summary:

```bash
./monitoring/system_health_summary.sh
```

---

## Development / Git Workflow

To add and commit the monitoring scripts:

```bash
git add monitoring/*.sh
git commit -m "Add monitoring scripts suite" \
  -m "CPU/memory/disk/inode checks plus system info, network summary and top process views."
```

---

## Requirements

* Linux system with GNU core utilities
* Bash 4.x or newer
* systemd (for service checks)

---

## License

See the LICENSE file for details.


