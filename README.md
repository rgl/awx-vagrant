# About

My Ansible AWX playground.

## Usage (libvirt/ubuntu-20.04)

Install the [Ubuntu 20.04 Vagrant Box](https://github.com/rgl/ubuntu-vagrant).

Bring up the `awx` vagrant environment (here it takes about 20m to be ready, but YMMV):

```bash
time vagrant up --provider=libvirt --no-destroy-on-error --no-tty
```

Access AWX at the returned endpoint. For example:

http://192.168.121.42:30080

Use the `admin`/`admin` credentials.

Follow the next inner sections to execute a playbook.

### Add Execution Environments

Go to the `Administration`/`Execution Environments`/`Create new execution environment` page. For example:

http://192.168.121.42:30080/#/execution_environments/add

Add a new Execution Environment with the following properties:

* Name: `My Ubuntu EE (latest)`
* Image: `my-ubuntu-ee:latest`
* Pull: `Only pull the image if its not present before running.`

**NB** This image was built in [`provision-my-ubuntu-ee.sh`](provision-my-ubuntu-ee.sh).

Add a new Execution Environment with the following properties:

* Name: `My Windows EE (latest)`
* Image: `my-windows-ee:latest`
* Pull: `Only pull the image if its not present before running.`

**NB** This image was built in [`provision-my-windows-ee.sh`](provision-my-windows-ee.sh).

### Add Inventory

Go to the `Resources`/`Inventories`/`Create new inventory` page. For example:

http://192.168.121.42:30080/#/inventories/inventory/add

Add a new Inventory with the following properties:

* Name: `My Lab`

Click the `Hosts` tab and add a new Host with the following properties:

* Name: `dm1`
* Variables YAML:
    ```yaml
    ---
    ansible_host: 192.168.1.77
    ```

And repeat the process for all your hosts.

### Add Credentials

Go to the `Resources`/`Credentials`/`Create New Credential` page. For example:

http://192.168.121.42:30080/#/credentials/add

Add a new Credential with the following properties:

* Name: `vagrant (Ubuntu My Lab)`
* Credential Type: `Machine`
* Username: `vagrant`
* Password: `vagrant`
* Privilege Escalation Method: `sudo`
* Privilege Escalation Username: `vagrant`
* Privilege Escalation Password: `vagrant`

Add a new Credential with the following properties:

* Name: `Administrator (Windows My Lab)`
* Credential Type: `Machine`
* Username: `Administrator`
* Password: `vagrant`

### Add Projects

Go to the `Resources`/`Projects`/`Create New Project` page. For example:

http://192.168.121.42:30080/#/projects/add

Add a new Project with the following properties:

* Name: `My Ubuntu`
* Execution Environment: `My Ubuntu EE (latest)`
* Source Control Type: `Git`
* Source Control URL: `https://github.com/rgl/my-ubuntu-ansible-playbooks.git`
* Source Control Branch/Tag/Commit: `main`
* Options: `clean`

Add a new Project with the following properties:

* Name: `My Windows`
* Execution Environment: `My Windows EE (latest)`
* Source Control Type: `Git`
* Source Control URL: `https://github.com/rgl/my-windows-ansible-playbooks.git`
* Source Control Branch/Tag/Commit: `main`
* Options: `clean`

### Add Templates

Go to the `Resources`/`Templates`/`Create New Job Template` page. For example:

http://192.168.121.42:30080/#/templates/job_template/add

Add a new Project with the following properties:

* Name: `My Ubuntu (development)`
* Inventory: `My Lab`
* Project: `My Ubuntu`
* Playbook: `development.yml`
* Credentials: `vagrant (Ubuntu My Lab)`
* Options: `Privilege Escalation` and `Enable Fact Storage`

Add a new Project with the following properties:

* Name: `My Windows (development)`
* Inventory: `My Lab`
* Project: `My Windows`
* Playbook: `development.yml`
* Credentials: `Administrator (Windows My Lab)`
* Variables YAML:
    ```yaml
    ansible_connection: psrp
    ansible_psrp_protocol: http
    ansible_psrp_message_encryption: never
    ansible_psrp_auth: credssp
    ```
* Options: `Enable Fact Storage`

### Execute Playbook

A Playbook is indirectly executed by Launching a Template.

For example, go to the `Resources`/`Templates`/`My Ubuntu (development)` page
and click the Launch (the rocket icon) button.

## Reference

* [AWX](https://github.com/ansible/awx)
* [AWX Operator](https://github.com/ansible/awx-operator)
* [Automation Controller User Guide](https://docs.ansible.com/automation-controller/latest/html/userguide/index.html)
  * [Execution Environments](https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html)
* [Ansible Builder](https://ansible-builder.readthedocs.io)
* [Ansible Runner](https://ansible-runner.readthedocs.io)
* Container images sources:
  * [quay.io/ansible/ansible-runner:latest](https://github.com/ansible/ansible-runner/blob/devel/Dockerfile)
  * [quay.io/ansible/ansible-builder:latest](https://github.com/ansible/ansible-builder/blob/devel/Containerfile)
  * [quay.io/ansible/python-builder:latest](https://github.com/ansible/python-builder-image/blob/main/Containerfile)
  * [quay.io/ansible/python-base:latest](https://github.com/ansible/python-base-image/blob/main/Containerfile)

## Alternatives

* [Ansible Semaphore](https://github.com/ansible-semaphore/semaphore)
