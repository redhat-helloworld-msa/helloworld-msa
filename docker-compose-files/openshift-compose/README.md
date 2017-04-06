### OpenShift import docker-compose


Start ADB/CDK

To get latest openshift edit Vagrantfile make `IMAGE_TAG` to `IMAGE_TAG="latest"`
```bash
vagrant up && vagrant provision
vagrant ssh
```

ADB/CDK might have the older `oc` binary so download the latest `oc` binary from [Origin release page](https://github.com/openshift/origin/releases/)

Download the docker-compose.yml file.

```bash
curl -O https://raw.githubusercontent.com/redhat-helloworld-msa/helloworld-msa/master/docker-compose-files/openshift-compose/docker-compose.yml
```

If using CDK edit environment variable `OS_SUBDOMAIN` for `frontend` service in the downloaded `docker-compose.yml` file to look something like this:

```yaml
    environment:
      - OS_SUBDOMAIN=rhel-cdk.10.1.2.2.xip.io
      - OS_PROJECT=helloworld-msa
```

Create new-project
```bash
oc login -u openshift-dev -p devel
oc new-project helloworld-msa
```

Allow container to run at any user ID for `helloworld-msa` project

```bash
oc login -u admin -p admin
oadm policy add-scc-to-user anyuid -n helloworld-msa -z default
```

Import docker compose file into openshift

```bash
oc login -u openshift-dev -p devel
oc import docker-compose -f docker-compose.yml
```

Manually creates routes
```bash
for SERVICE in hola hello aloha api-gateway bonjour frontend namaste ola zipkin-mysql zipkin-query zipkin-query-admin
do
    oc expose service $SERVICE
done
```

Goto respective link to access the application:

- ADB: http://frontend-helloworld-msa.centos7-adb.10.1.2.2.xip.io/
- CDK: http://frontend-helloworld-msa.rhel-cdk.10.1.2.2.xip.io/

Everything there works except for the Hystrix Dashboard.

