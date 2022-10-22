# cloud-init-generator

This script will quickly modify a cloud-init user-data template that can be used to provision VMs and Metal. 

## Usage

```bash

./cigen.sh [-h] [-v] [-s] [-upd] [-upg] [-p <password>] [-u <user>] [-gw <gateway ip>] -dns [<dns server ip> ][-gh <user>] [-n <vm name>]

Available options:

-h, --help              Print this help and exit

-v, --verbose           Print script debug info

-upd, --update          Update apt packages during provisioning
                        Defaults to False

-upg, --upg             Upgrade packages during provisioning
                        Defaults to False

-t, --template          The template to use as the base for clopud-init.
                        Templates are located in the templates directory.
                        Defaults to 'slim.yaml' if no value specified.

-p, --password          Password to set up for the VM Users. 
                        Defaults to 'password' if no value is specified

-u, --username          Username for non-system account
                        Defaults to the current shell user

-gh, --github-username  (Optional) Github username from which to pull public keys

-n, --vm-name           Hostname/name for the Virtual Machine. Influences the 
                        name of the syste account - no special chars plz.

-e, --extra-vars        Some templates will require extra values.
                        Use this option to supply these values as 
                        Key-Value-Pairs separated via commas.
                        Example: -e "VAR0='some string'","VAR1=$(pwd)"
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
