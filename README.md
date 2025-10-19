# Cloud-Init Generator [![GitHub Release](https://img.shields.io/github/v/release/cloudymax/cloud-init-generator?style=flat&labelColor=858585&color=6BF847&logo=GitHub&logoColor=white)](https://github.com/cloudymax/cloud-init-generator/releases)

## Options

```bash
💁 This script will quickly modify a cloud-init user-data template that can be used to provision virtual-machines, metal, and containers.

Available options:

-h, --help              Print this help and exit

-v, --verbose           Print script debug info

-q, --quiet             Only print final userdata

-u, --userdata          Path to cloud-init user-data file (required)

-n, --networkdata       Path to cloud-init networkdata file (optional)

-k, --kubernetes        Create kubernetes secrets from user and network data (optional)

-e, --envsubst          Enable usage of envsubst, disabled by default (optional)

-s, --salt              Salt to use when encrypting password (optional)
```

## Basic Usage

```bash
USERNAME="runner"
RUNNER_PASSWORD="SomeP@ssw0rd!"
SECRET_NAME="runner-user-data"

docker build -t cigen . && \
docker run -it -u appuser -v $(pwd)/test-configs:/configs \
    -v /Users/max/.config/kube:/kube \
    --env USERNAME=$USERNAME \
    --env SECRET_NAME=$SECRET_NAME \
    cigen --userdata /configs/userdata.yaml \
    --networkdata /configs/networkdata.yaml \
    --kubernetes \
    --envsubst
```

## Why Cloud-Init?

Cloud-Init officially supports 8 OSs - Ubuntu, Arch Linux, CentOS, Red Hat, FreeBSD, Fedora, Gentoo Linux, and openSUSE. These examples have been developed and tested for use with Ubuntu.

Use on bare-metal:
- [PXEless](https://github.com/cloudymax/pxeless)

On self-hosted VMs:
- [Scrap-Metal](https://github.com/cloudymax/Scrap-Metal)
- [Multipass](https://ubuntu.com/blog/using-cloud-init-with-multipass)

Or via Terraform on most major clouds:
- [Equinix Metal](https://registry.terraform.io/providers/equinix/equinix/latest/docs/resources/equinix_metal_device)
- [AWS EC2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [Azure Compute](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine)
- [Digital Ocean Droplets](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet)
- [Google Compute Engine (as metadata field)](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)
- [Terraform templating module for cloud-init](https://registry.terraform.io/providers/hashicorp/cloudinit/2.2.0)

Cloud-Init Docs:
- [Cloud-Init Official Docs](https://cloudinit.readthedocs.io/en/latest/)
- [Extra examples from Canonical](https://github.com/canonical/cloud-init/tree/main/doc/examples)

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
