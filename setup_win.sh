minishift delete --force --clear-cache
REM sudo rm -Rf ~/.minishift/
minishift profile set msa-tutorial
minishift config set memory 10GB
minishift config set cpus 3
minishift config set image-caching true
minishift config set openshift-version v3.11.0
minishift addons enable anyuid
minishift addons enable admin-user
REM minishift start --vm-driver hyperkit
eval $(minishift oc-env)
oc login `minishift ip`:8443 -u developer -p developer
oc new-project helloworld-msa
git clone https://github.com/redhat-helloworld-msa/hola
cd hola/
# Remove env setting from keycloack.json and hardcode ip OR fix to pickup env
# Optionally convert to MicroProfile Config instead of Deltaspike
oc new-build --binary --name=hola -l app=hola
mvn package; oc start-build hola --from-dir=. --follow
oc new-app hola -l app=hola,hystrix.enabled=true
oc expose service hola
oc set env dc KEYCLOAK_AUTH_SERVER_URL="" -l app
oc set probe dc/hola --readiness --get-url=http://:8080/api/health
cd ..
git clone https://github.com/redhat-helloworld-msa/aloha
cd aloha/
oc new-build --binary --name=aloha -l app=aloha
mvn package; oc start-build aloha --from-dir=. --follow
oc new-app aloha -l app=aloha,hystrix.enabled=true
oc expose service aloha
oc set env dc/aloha AB_ENABLED=jolokia; oc patch dc/aloha -p '{"spec":{"template":{"spec":{"containers":[{"name":"aloha","ports":[{"containerPort": 8778,"name":"jolokia"}]}]}}}}'
oc set probe dc/aloha --readiness --get-url=http://:8080/api/health
cd ..
git clone https://github.com/redhat-helloworld-msa/ola
cd ola/
oc new-build --binary --name=ola -l app=ola
mvn package; oc start-build ola --from-dir=. --follow
oc new-app ola -l app=ola,hystrix.enabled=true
oc expose service ola
oc set env dc/ola AB_ENABLED=jolokia; oc patch dc/ola -p '{"spec":{"template":{"spec":{"containers":[{"name":"ola","ports":[{"containerPort": 8778,"name":"jolokia"}]}]}}}}'
oc set probe dc/ola --readiness --get-url=http://:8080/api/health
cd ..
git clone https://github.com/redhat-helloworld-msa/bonjour
cd bonjour/
oc new-build --binary --name=bonjour -l app=bonjour
npm install; oc start-build bonjour --from-dir=. --follow
oc new-app bonjour -l app=bonjour
oc expose service bonjour
oc set probe dc/bonjour --readiness --get-url=http://:8080/api/health
cd ..
git clone https://github.com/redhat-helloworld-msa/api-gateway
cd api-gateway/
oc new-build --binary --name=api-gateway -l app=api-gateway
mvn package; oc start-build api-gateway --from-dir=. --follow
oc new-app api-gateway -l app=api-gateway,hystrix.enabled=true
oc expose service api-gateway
oc set env dc/api-gateway AB_ENABLED=jolokia; oc patch dc/api-gateway -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-gateway","ports":[{"containerPort": 8778,"name":"jolokia"}]}]}}}}'
oc set probe dc/api-gateway --readiness --get-url=http://:8080/health
cd ..
git clone https://github.com/redhat-helloworld-msa/frontend
cd frontend/
oc new-build --binary --name=frontend -l app=frontend
npm install; oc start-build frontend --from-dir=. --follow
oc new-app frontend -l app=frontend
oc expose service frontend
oc set env dc/frontend OS_SUBDOMAIN=`minishift ip`.nip.io
oc set probe dc/frontend --readiness --get-url=http://:8080/
oc process -f http://central.maven.org/maven2/io/fabric8/kubeflix/packages/kubeflix/1.0.17/kubeflix-1.0.17-kubernetes.yml | oc create -f -
oc expose service hystrix-dashboard --port=8080
oc policy add-role-to-user admin system:serviceaccount:helloworld-msa:turbine
oc set env dc/frontend ENABLE_HYSTRIX=true
oc process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/0.1.2/all-in-one/jaeger-all-in-one-template.yml | oc create -f -
oc set env dc -l app JAEGER_SERVER_HOSTNAME=jaeger-all-in-one  # redeploy all services with tracing
oc set env dc/frontend ENABLE_JAEGER=true
oc new-project sso
cd ..
git clone https://github.com/redhat-helloworld-msa/sso
cd sso/
oc new-build --binary --name keycloak
oc start-build keycloak --from-dir=. --follow
oc new-app keycloak
oc expose svc/keycloak
oc set probe dc/keycloak --readiness --get-url=http://:8080/auth``
oc set env dc/keycloak OS_SUBDOMAIN=app.`minishift ip`.nip.io
oc project helloworld-msa
oc set env dc KEYCLOAK_AUTH_SERVER_URL=http://keycloak-sso.`minishift ip`.nip.io/auth -l app
oc set env dc/frontend ENABLE_SSO=true
# Set Valid Redirect URIs to * in Keycloak admin portal. 
cd ..
git clone https://github.com/redhat-helloworld-msa/api-management
cd api-management/
oc new-build --binary --name api-management -e BACKEND_URL=http://127.0.0.1:8081
oc set env bc/api-management OS_SUBDOMAIN=`minishift ip`.nip.io
oc start-build api-management --from-dir=. --follow
oc new-app api-management
oc expose svc/api-management --name api-bonjour
oc expose svc/api-management --name api-hola
oc expose svc/api-management --name api-ola
oc expose svc/api-management --name api-aloha
oc set probe dc/api-management --readiness --get-url=http://:8081/status/ready
oc set env dc/frontend ENABLE_THREESCALE=true
oc set env dc/hola hello="Hola de Env var"
oc set env dc/hola hello-
oc create configmap translation --from-file=translation.properties
oc get configmap translation -o yaml
oc patch dc/hola -p '{"spec":{"template":{"spec":{"containers":[{"name":"hola","volumeMounts":[{"name":"config-volume","mountPath":"/etc/config"}]}],"volumes":[{"name":"config-volume","configMap":{"name":"translation"}}]}}}}'
oc set env dc/hola JAVA_OPTIONS="-Dconf=/etc/config/translation.properties"
oc login -u admin -p admin
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:ci:jenkins -n ci
oc login -u developer -p developer
oc new-project ci
oc create -f https://raw.githubusercontent.com/redhat-helloworld-msa/aloha/master/pipeline.yml
oc project helloworld-msa
#Change aloha source code
mvn clean package; oc start-build aloha --from-dir=. --follow
minishift console