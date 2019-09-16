#!/bin/bash
# Copyright 2019, Oracle Corporation and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

set -e  # Exit immediately if a command exits with a non-zero status.

METRIC_EXPORTER_VERSION=1.1.0
LOGGING_EXPORTER_VERSION=1.0.0
WDT_VERSION=1.3.0

TMP_DIR=$PWD/tmp
APP_DIR=${TMP_DIR}/archive/wlsdeploy/applications
LIB_DIR=${TMP_DIR}/archive/wlsdeploy/classpathLibraries

# Create two webapps: testwebapp and wls-exporter.
function createArchive() {
  mkdir -p ${APP_DIR}
  mkdir -p ${LIB_DIR}

  echo 'Build the test webapp...'
  cd test-webapp/src/main/webapp
  jar -cf ${APP_DIR}/testwebapp.war .
  cd -

  echo 'Download the metrics exporter...'
  cd $TMP_DIR
  wget https://github.com/oracle/weblogic-monitoring-exporter/releases/download/v${METRIC_EXPORTER_VERSION}/get${METRIC_EXPORTER_VERSION}.sh
  chmod +x get${METRIC_EXPORTER_VERSION}.sh
  ./get${METRIC_EXPORTER_VERSION}.sh ../../../dashboard/exporter-config.yaml
  cp wls-exporter.war ${APP_DIR}
  cd -

  echo 'Download the logging exporter...'
  wget -O ${LIB_DIR}/wls-logging-exporter.jar \
     https://github.com/oracle/weblogic-logging-exporter/releases/download/v1.0.0/weblogic-logging-exporter-${LOGGING_EXPORTER_VERSION}.jar

  wget -O ${LIB_DIR}/snakeyaml-1.23.jar \
     http://repo1.maven.org/maven2/org/yaml/snakeyaml/1.23/snakeyaml-1.23.jar

  echo 'Build the WDT archive...'
  jar cvf ${TMP_DIR}/archive.zip  -C ${TMP_DIR}/archive wlsdeploy

  rm -rf ${TMP_DIR}/archive
}

function cleanTmpDir() {
  rm -rf test-webapp/target
  rm -rf ${TMP_DIR}
}

function buildImage() {
  cp scripts/* ${TMP_DIR}
  echo "Update domain.properties with cmdline arguments..."
  sed -i "s/^DOMAIN_NAME.*/DOMAIN_NAME=$1/g" ${TMP_DIR}/domain.properties
  sed -i "s/^ADMIN_USER.*/ADMIN_USER=$2/g" ${TMP_DIR}/domain.properties
  sed -i "s/^ADMIN_PWD.*/ADMIN_PWD=$3/g" ${TMP_DIR}/domain.properties
  sed -i "s/^MYSQL_USER.*/MYSQL_USER=$4/g" ${TMP_DIR}/domain.properties
  sed -i "s/^MYSQL_PWD.*/MYSQL_PWD=$5/g" ${TMP_DIR}/domain.properties

  echo 'Download the wdt zip...'
  wget -P ${TMP_DIR} \
    https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-${WDT_VERSION}/weblogic-deploy.zip

  imageName=$1-image:1.0
  echo "Build the domain image $imageName..."
  docker build . --force-rm -t $imageName
}

if [ "$#" != 5 ] ; then
  echo "usage: $0 domainName adminUser adminPwd mysqlUser mysqlPwd"
  exit 1 
fi

cleanTmpDir
createArchive
buildImage $@
cleanTmpDir

