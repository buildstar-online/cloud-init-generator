# cloud-init-generator

Generates the user-data section of a cloud-init configuration file from a template.

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
