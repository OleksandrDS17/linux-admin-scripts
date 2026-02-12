# linux-admin-scripts
Bash automation for user management, service control and administrative diagnostics on Linux systems

# Linux Administration & Bash Automatisierung

A collection of practical Bash scripts created to support daily Linux administration tasks.  
The focus of this repository is automation, service monitoring and extraction of system information.

## Goals of the project
- automate recurring administrative activities  
- simplify system checks  
- provide structured output for further analysis  
- improve reliability and speed of operational tasks  

## Implemented topics
- user and group management  
- service status verification  
- system information collection  
- log and process filtering  

## Technologies & Tools
- Bash  
- systemctl  
- grep  
- awk  
- standard GNU/Linux utilities  

## Example use cases
- quick verification whether important services are running  
- extracting relevant system data for troubleshooting  
- administrative preparation before maintenance  
- repetitive daily checks  

## Structure
Each script is self-contained and can be executed independently.  
Most scripts require standard user permissions, some may need elevated rights.

## Example execution
```bash
chmod +x script.sh
./script.sh

