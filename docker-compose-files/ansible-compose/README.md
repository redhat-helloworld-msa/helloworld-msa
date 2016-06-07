### Ansible docker_service module

Since docker_service depends on docker-compose >= 1.7.0, we need to use docker-engine and docker-py versions which are not yet available in CentOS or EPEL repositories.

Before we get the latest versions of docker and docker-py, let's remove the existing packages on ADB.

```bash
sudo yum remove -y python-docker-py docker*
```

Then, we add the YUM repository in ADB from where we will be installing the docker-engine.

```
if [ ! -f /etc/yum.repos.d/docker.repo ]; then
sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
fi
```
Now let's install docker-engine and other dependencies which will be required for the setup.

```bash
sudo yum install -y gcc libffi-devel python-devel openssl-devel docker-engine
```

Next, we need to install docker-py, docker-compose and ansible from pip.

```bash
sudo easy_install pip
sudo pip install --upgrade setuptools docker-compose docker-py ansible
```
Start the docker service.

```bash
sudo systemctl start docker
```

Create a project directory for helloworld-msa and enter it.

```bash
mkdir msa
cd msa
```

Next, we need to set the environment variables which we require to communicate with the application.

```bash
curl -O https://raw.githubusercontent.com/redhat-helloworld-msa/helloworld-msa/master/docker-compose-files/ansible-compose/msa_env_export
```

We need to change the HOSTIP environment variable in this file to match the IP of the machine on which we are deploying the application. This IP should be accessible by the browser which will be used to access the application endpoints.

Next, we export the environment variables.

```bash
source msa_env_export
```

Next, we get the docker-compose.yaml file for running helloworld-msa.

```bash
curl -O https://raw.githubusercontent.com/redhat-helloworld-msa/helloworld-msa/master/docker-compose-files/ansible-compose/docker-compose.yaml
```

A sample working ansible playbook looks like this, but feel free to modify this to suit your requirements.

```yaml
- name: deploy docker compose artifacts
  hosts: localhost
  connection: local
  tasks:
    - name: compose_up
      docker_service:
        project_src: /home/vagrant/msa/
        project_name: MSA
        state: present
      tags:
      - up

    - name: compose_down
      docker_service:
        project_src: /home/vagrant/msa/
        project_name: MSA
        state: absent
      tags:
      - down
```

Bring the application up or down using the following commands:

```bash
ansible-playbook -t up ansible-compose.yaml
ansible-playbook -t down ansible-compose.yaml
```
