set -u  #Treat unset variables as an error when substituting.

source waitUtil.sh

echo "PV_ROOT=$PV_ROOT"

# delete grafana
helm delete --purge grafana
kubectl -n monitoring delete secret grafana-secret
kubectl delete -f grafana/persistence.yaml

# delete prometheus
helm delete --purge prometheus
kubectl delete -f prometheus/persistence.yaml
kubectl delete -f prometheus/alert-persistence.yaml

kubectl delete ns monitoring
waitNSTerm monitoring

echo "Clean data in PV"
docker run --rm -v $PV_ROOT:/tt -v $PWD/util:/util  nginx /util/clean-monitor.sh
