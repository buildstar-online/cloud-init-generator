# cloud-init-generator

Generates the user-data section of a cloud-init configuration file from a template.

## Usage

```bash
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-s] [-upd] [-upg] [-p <password>] [-u <user>] [-gh <user>] [-n <name>]

💁 This script will quickly modify a cloud-init user-data template that can be used to provision virtual-machines, metal, and containers.

Available options:

-h, --help              Print this help and exit

-v, --verbose           Print script debug info

-s, --slim              Use a minimal version of the user-data template.

-upd, --update          Update apt packages during provisioning

-upg, --upg             Upgrade packages during provisioning

-p, --password          Password to set up for the VM Users.

-u, --username          Username for non-system account

-i, --ip-address        IP address for netplan to apply.

-gw, --gateway          IP address for the default network gateway

-dns, --dns-server      IP address for your DNS server

-gh, --github-username  Github username from which to pull public keys

-n, --vm-name           Hostname/name for the Virtual Machine. Influences the name of the 
                        system account - no special chars plz.
```
cloud-init logs are in /run/cloud-init/result.json

If you want to debug the user-data in cloud-init, we can try the following steps:

- https://cloudinit.readthedocs.io/en/latest/topics/debugging.html

- Reset and re-run
  ```bash
  sudo rm -rf /var/lib/cloud/*
  sudo cloud-init init
  sudo cloud-init modules -m final
  ```

- Analyze logs
  ```bash
  sudo cloud-init analyze show -i /var/log/cloud-init.log
  sudo cloud-init analyze dump -i /var/log/cloud-init.log
  sudo cloud-init analyze blame -i /var/log/cloud-init.log
  ```

- Run single module
  `sudo cloud-init single --name cc_ssh --frequency always`
