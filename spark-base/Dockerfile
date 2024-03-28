#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
ARG JAVA_VERSION=11
ARG BASE_IMAGE=eclipse-temurin:${JAVA_VERSION}-jre-jammy 
FROM $BASE_IMAGE

ARG spark_uid=185

ARG SPARK_VERSION=3.2.1
ARG HADOOP_VERSION=3.2
ARG SCALA_VERSION=2.12
ARG SPARK_DIST_DOWNLOAD_URL=https://archive.apache.org/dist/spark

ENV SPARK_HOME       /opt/spark
ENV SPARK_CONF_DIR   ${SPARK_HOME}/conf

ENV SPARK_VERSION    ${SPARK_VERSION}
ENV HADOOP_VERSION   ${HADOOP_VERSION}
ENV SCALA_VERSION    ${SCALA_VERSION}

RUN groupadd --system --gid=${spark_uid} spark && \
    useradd --system --uid=${spark_uid} --gid=spark spark

RUN set -ex; \
    apt-get update; \
    ln -s /lib /lib64; \
    apt install -y --no-install-recommends gnupg2 bash tini libc6 libpam-modules krb5-user libnss3 procps net-tools gosu libnss-wrapper curl; \
    mkdir -p ${SPARK_HOME}; \
    mkdir -p ${SPARK_HOME}/work-dir; \
    chmod g+w ${SPARK_HOME}/work-dir; \
    chown -R spark:spark ${SPARK_HOME}; \
    rm /bin/sh; \
    ln -sv /bin/bash /bin/sh; \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su; \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd; \
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

RUN set -ex;\
    export WORK_DIR="$(mktemp -d)"; \
    DIST=spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}; \
    if [ "${SCALA_VERSION}" = "2.13" ]; then \
      DIST+=-scala${SCALA_VERSION}; \
    fi; \
    curl --retry 3 --retry-all-errors -k ${SPARK_DIST_DOWNLOAD_URL}/${DIST}.tgz -o ${WORK_DIR}/spark.tgz; \
    curl --retry 3 --retry-all-errors -k ${SPARK_DIST_DOWNLOAD_URL}/${DIST}.tgz.asc -o ${WORK_DIR}/spark.tgz.asc; \
    curl --retry 3 --retry-all-errors -k https://downloads.apache.org/spark/KEYS -o ${WORK_DIR}/KEYS; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --import ${WORK_DIR}/KEYS; \
    gpg --batch --verify ${WORK_DIR}/spark.tgz.asc ${WORK_DIR}/spark.tgz; \
    tar --strip-components=1 -zxvf ${WORK_DIR}/spark.tgz -C ${SPARK_HOME}/; \
    chown -R spark:spark ${SPARK_HOME}/; \
    mv ${SPARK_HOME}/kubernetes/dockerfiles/spark/decom.sh /opt/; \
    mv ${SPARK_HOME}/kubernetes/tests ${SPARK_HOME}/; \
    chmod a+x /opt/decom.sh; \
    gpgconf --kill all; \
    rm -rf ${GNUPGHOME} ${WORK_DIR}; \
    rm -fr ${SPARK_HOME}/conf rm -fr ${SPARK_HOME}/yarn rm -fr ${SPARK_HOME}/kubernetes

COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod a+x /opt/entrypoint.sh

WORKDIR ${SPARK_HOME}/work-dir

USER spark

ENTRYPOINT [ "/opt/entrypoint.sh" ]

