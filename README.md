# cloud-init-generator

This script will quickly modify a cloud-init user-data template that can be used to provision VMs and Metal. 

## Usage

```bash

./cigen.sh [-h] [-v] [-s] [-upd] [-upg] [-p <password>] [-u <user>] [-gw <gateway ip>] -dns [<dns server ip> ][-gh <user>] [-n <vm name>]

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

## Debugging 

Docs link: https://cloudinit.readthedocs.io/en/latest/topics/debugging.html

cloud-init logs are located in:

- `/run/cloud-init/result.json`
- `/var/log/cloud-init.log`
- `/var/log/cloud-init-output.log`

If you want to debug the user-data in cloud-init, try the following steps:

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
