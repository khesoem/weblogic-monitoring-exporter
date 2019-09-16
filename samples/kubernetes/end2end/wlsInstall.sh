#!/bin/bash
# set -e  Exit immediately if a command exits with a non-zero status.
# set -u  Treat unset variables as an error when substituting and 
set -eu

source waitUtil.sh

OPT_VERSION=2.3.0
WLS_VERSION=12.2.1.3

echo "install mysql server and prepare db used by wls domains"
kubectl apply -f ./mysql/persistence.yaml
kubectl apply -f ./mysql/mysql.yaml
waitPodsReady default app=mysql 1 mysql
sleep 15s # walk around ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)
POD_NAME=$(kubectl get pod -l app=mysql -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD_NAME -- mysql -p123456 -e "CREATE DATABASE domain1;"
kubectl exec -it $POD_NAME -- mysql -p123456 -e "CREATE USER 'wluser1' IDENTIFIED BY 'wlpwd123';"
kubectl exec -it $POD_NAME -- mysql -p123456 -e "GRANT ALL ON domain1.* TO 'wluser1';"

echo "prepare weblogic images"
docker pull container-registry.oracle.com/middleware/weblogic:${WLS_VERSION}
docker pull oracle/weblogic-kubernetes-operator:${OPT_VERSION}

echo "install WebLogic operator"
helm repo add weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts

kubectl create namespace weblogic-operator1
kubectl create serviceaccount -n weblogic-operator1 sample-weblogic-operator-sa

helm install weblogic-operator/weblogic-operator --version ${OPT_VERSION} --name weblogic-operator --namespace weblogic-operator1 \
  --set serviceAccount=sample-weblogic-operator-sa \
  --set image=oracle/weblogic-kubernetes-operator:${OPT_VERSION} \
  --set "domainNamespaces={default}" \
  --wait

waitCRDReady

echo "build domain1 image"
cd demo-domains/domainBuilder
./build.sh domain1 weblogic welcome1 wluser1 wlpwd123
cd ../..

echo "create domain1"
kubectl -n default create secret generic domain1-weblogic-credentials \
      --from-literal=username=weblogic \
      --from-literal=password=welcome1

kubectl apply -f demo-domains/domain1.yaml

waitDomainReady default domain1

