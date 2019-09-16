#!/bin/bash
# set -e  Exit immediately if a command exits with a non-zero status.
# set -u  Treat unset variables as an error when substituting and 
set -eu

source waitUtil.sh

kubectl create ns monitoring
echo "install promethues"
kubectl apply -f prometheus/alert-persistence.yaml
kubectl apply -f prometheus/persistence.yaml
helm install --wait --name prometheus --namespace monitoring --values  prometheus/values.yaml stable/prometheus

echo "install grafana"
kubectl apply -f grafana/persistence.yaml
# grafana admin credential
kubectl --namespace monitoring create secret generic grafana-secret --from-literal=username=admin --from-literal=password=12345678
helm install --wait --name grafana --namespace monitoring --values grafana/values.yaml stable/grafana

waitPodsReady monitoring app=prometheus 4 prometheus
waitPodsReady monitoring app=grafana 1 grafana

echo "create datasource and dashboard to Grafana"
curl -v -H 'Content-Type: application/json' -H "Content-Type: application/json" \
  -X POST http://admin:12345678@$HOSTNAME:31000/api/datasources/ \
  --data-binary @grafana/datasource.json

curl -v -H 'Content-Type: application/json' -H "Content-Type: application/json" \
  -X POST http://admin:12345678@$HOSTNAME:31000/api/dashboards/db \
  --data-binary @grafana/dashboard.json

