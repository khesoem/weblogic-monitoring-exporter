# Copyright 2019, Oracle Corporation and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

FROM container-registry.oracle.com/middleware/weblogic:12.2.1.3

ENV SCRIPTS_DIR="/tmp/scripts/"
ENV WEBLOGIC_LOGGING_EXPORTER_CONFIG_FILE=/u01/oracle/user-projects/domains/WebLogicLoggingExporter.yaml 
ENV CLASSPATH=/u01/oracle/user-projects/domains/domain1/wlsdeploy/classpathLibraries/snakeyaml-1.23.jar:/u01/oracle/user-projects/domains/domain1/wlsdeploy/classpathLibraries/wls-logging-exporter.jar

RUN mkdir -p $SCRIPTS_DIR
COPY tmp/* $SCRIPTS_DIR
RUN $SCRIPTS_DIR/create-domain.sh && \
    rm -rf ${SCRIPTS_DIR}

WORKDIR $ORACLE_HOME
