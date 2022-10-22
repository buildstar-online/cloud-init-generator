# cloud-init-generator

This script will quickly modify a cloud-init user-data template that can be used to provision local or cloud-based VMs and Metal. Today, Cloud-Init officially supports 8 OSs - Ubuntu, Arch Linux, CentOS, Red Hat, FreeBSD, Fedora, Gentoo Linux, and openSUSE. These examples have been developed and tested for use with Ubuntu.

Use with Terraform on most major cloud provders:
- [AWS EC2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [Azure Compute](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine)
- [Equinix Metal](https://registry.terraform.io/providers/equinix/equinix/latest/docs/resources/equinix_metal_device)
- [Google Compute Engine (as metadata field)](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)
- [Terraform templating module for cloud-init](https://registry.terraform.io/providers/hashicorp/cloudinit/2.2.0)


Docs:
- [Cloud-Init Official Docs](https://cloudinit.readthedocs.io/en/latest/)
- [Extra examples from Canonical](https://github.com/canonical/cloud-init/tree/main/doc/examples)

## Basic Usage

```bash

./cigen.sh --update --upgrade \
  --password "S0m3P@ssw0Rd!" \
  --github-username "cloudymax" \
  --username "cloudymax" \
  --vm-name "cloudyboi" \
  --template "slim.yaml"
```


```bash
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

## Advanced Usage with Extra Vars

Some templates will require additional variabels aside from those specified in the --help.
To supply extra variables used the `-e` or `--extra-vars` flag and provide the extra values as a comma-separated list of Key-Value-Pairs represented as strings without linebreaks or spaces between them.

Example:

```bash

./cigen.sh --update --upgrade \
  --password "S0m3P@ssw0Rd!" \
  --github-username "cloudymax" \
  --username "cloudymax" \
  --vm-name "cloudyboi" \
  --template "scrap-metal-auto-install.yaml" \
  --extra-vars "INTERFACE=enp4s0","IP_ADDRESS=192.168.50.100","GATEWAY_IP=192.168.50.1","DNS_SERVER_IP=192.168.50.50","ROOT_USER=max"
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
