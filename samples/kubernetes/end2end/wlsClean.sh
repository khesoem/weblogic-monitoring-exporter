#!/bin/bash
set -u  #Treat unset variables as an error when substituting.

source waitUtil.sh

echo "PV_ROOT=$PV_ROOT"

# delete wls domains
kubectl delete -f demo-domains/domain1.yaml
kubectl delete secret domain1-weblogic-credentials

waitDomainStopped default domain1

# delete wls operator
helm delete --purge sample-weblogic-operator
kubectl delete -n weblogic-operator1 serviceaccount sample-weblogic-operator-sa
kubectl delete namespace weblogic-operator1
rm -rf weblogic-kubernetes-operator

waitNSTerm weblogic-operator1

# delete sql server
kubectl delete  -f ./mysql/mysql.yaml
kubectl delete  -f ./mysql/persistence.yaml

# remove PV host folder
docker run --rm -v $PV_ROOT:/tt -v $PWD/util:/util  nginx /util/clean-wls.sh
echo "'$0 took $(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds to finish."
