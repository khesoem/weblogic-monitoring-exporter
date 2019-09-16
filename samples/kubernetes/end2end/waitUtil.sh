#!/bin/bash
# Copyright 2019, Oracle Corporation and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.


DEFAULT_MAX_WAIT=20

# Usage:
# waitUntil cmd expected_out okMsg failMsg <waitMaxCount>
function waitUntil() {
  cmd=$1
  expected_out=$2
  okMsg=$3
  failMsg=$4
  if [ $# = 5 ]; then
    max_wait=$5
  else
    max_wait=$DEFAULT_MAX_WAIT
  fi

  count=0
  echo "wait until $okMsg"
  while [ $count -lt $max_wait ]; do
    if [ "$($cmd)" = "$expected_out" ]; then
      echo $okMsg
      return 0
    fi
    #echo "wait until $okMsg"
    ((count=count+1))
    sleep 3 
  done
  echo "Error: $failMsg"
  return 1
}

# Usage: waitPodReady namespace podLabel podNum podName
function waitPodsReady() {
  expected_out=$3
  okMsg="$4 pod is ready"
  failMsg="fail to start $4 pod"

  waitUntil "checkPodsReadyCmd $1 $2" "$expected_out" "$okMsg" "$failMsg"
}

# usage: checkPodReadyCmd namespace podLabel
function checkPodsReadyCmd() {
  kubectl -n $1 get pod -l $2 -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' | grep true | wc -l
}

##########################  domain function end  #########################

# Usage: waitDomainReady namespace domainName
function waitDomainReady() {
  # get server number
  serverNum="$(kubectl -n $1 get domain $2 -o=jsonpath='{.spec.replicas}')"
  serverNum=$(expr $serverNum + 1)

  cmd="checkDomainReadyCmd $1 $2"
  expected_out=$serverNum
  okMsg="domain $2 is ready"
  failMsg="fail to start domain $2"

  waitUntil "$cmd" "$expected_out" "$okMsg" "$failMsg" 160
}

# Usage: checkDomainReadyCmd namespace domainName
function checkDomainReadyCmd() {
  kubectl -n $1 get pods -l weblogic.domainUID=$2,weblogic.createdByOperator=true \
        -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' | grep true | wc -l
}

# Usage: waitDomainStopped namespace domainName
function waitDomainStopped() {
  expected_out=0
  okMsg="domain $2 is stopped"
  failMsg="fail to stop domain $2"

  waitUntil "checkDomainStoppedCmd $1 $2" "$expected_out" "$okMsg" "$failMsg" 160
}

# Usage: checkDomainStoppedCmd namespace domainName
function checkDomainStoppedCmd() {
  kubectl -n $1 get all -l weblogic.domainUID=$2,weblogic.createdByOperator=true | wc -l
}

# wait until domain CRD is ready
function waitCRDReady() {
  expected_out=1
  okMsg="domain CRD is ready"
  failMsg="fail to create domain CRD"

  waitUntil checkCRDReadyCmd "$expected_out" "$okMsg" "$failMsg"
}

function checkCRDReadyCmd() {
  kubectl get crd domains.weblogic.oracle   --ignore-not-found | grep domains.weblogic.oracle  | wc -l
}
##########################  domain function end  #########################

function waitWebhook() {
  echo "sleep 1m to wait the alert fired."
  sleep 60
  count=0
  WEBHOOK_NAME=$(kubectl -n webhook get pod -l app=webhook -o jsonpath="{.items[0].metadata.name}")
  while [ $count -lt $DEFAULT_MAX_WAIT ]; do
    alertNum=$(kubectl -n webhook logs $WEBHOOK_NAME | grep -c '"alertname": "ClusterWarning"')
    if [ "$alertNum" > 0 ]; then
      echo "webhook receives an ClusterWarning alert"
      return 0
    fi
    #echo "wait until webhook receives an ClusterWarning alert"
    ((count=count+1))
    sleep 3 
  done
  echo "Error: webhook fails to receive the alert"
  return 1
}

# usage: waitUntilNSTerm ns_name 
function waitNSTerm() {
  expected_out=0
  okMsg="namespace $1 is termiated"
  failMsg="fail to termiate namespace $1"

  waitUntil "checkNSTermCmd $1" "$expected_out" "$okMsg" "$failMsg"
}

function checkNSTermCmd() {
  kubectl get ns $1  --ignore-not-found | grep $1 | wc -l
}

# Usage: waitUntilHttpReady name hostname url
function waitHttpReady() {
  expected_out=200
  okMsg="http to $1 is ready"
  failMsg="fail to access http to $1 "

  waitUntil "checkHttpCmd $2 $3" "$expected_out" "$okMsg" "$failMsg"
}

# Usage: checkHTTPCmd hostname url
function checkHttpCmd() {
  curl -s -o /dev/null -w "%{http_code}"  -H "host: $1" $2
}

# Usage: waitUntilHttpsReady name hostname url
function waitHttpsReady() {
  expected_out=200
  okMsg="https to $1 is ready"
  failMsg="fail to access https to $1 "

  waitUntil "checkHttpsCmd $2 $3" "$expected_out" "$okMsg" "$failMsg"
}

# Usage: checkHTTPSCmd hostname url
function checkHttpsCmd() {
  curl -k -s -o /dev/null -w "%{http_code}"  -H "host: $1" $2
}

function test() {
  waitPodsReady monitoring app=prometheus 3 prometheus
  waitPodsReady monitoring app=grafana 1 grafana
  waitCRDReady
  waitPodsReady default app=mysql 1 mysql
  waitDomainReady default domain1
  waitDomainReady test1 domain3
  waitPodsReady default app=jmsclient 1 jmsclient
}


