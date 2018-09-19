FROM java:8

ENV HBASE_VERSION 1.2.7
ENV HBASE_INSTALL_DIR /opt/hbase

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV URL http://mirrors.shu.edu.cn/apache/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz
RUN echo $URL

RUN mkdir -p ${HBASE_INSTALL_DIR} && \
    curl -L ${URL} | tar -zx --strip=1 -C ${HBASE_INSTALL_DIR}

RUN sed -i "s/httpredir.debian.org/mirrors.163.com/g" /etc/apt/sources.list
# build LZO
WORKDIR /tmp
RUN apt-get update && \
    apt-get install -y build-essential maven lzop liblzo2-2 && \
    wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz && \
    tar zxvf lzo-2.10.tar.gz && \
    cd lzo-2.10 && \
    ./configure --enable-shared --prefix /usr/local/lzo-2.10 && \
    make && make install && \
    cd .. && git clone https://github.com/twitter/hadoop-lzo.git && cd hadoop-lzo && \
    git checkout release-0.4.20 && \
    C_INCLUDE_PATH=/usr/local/lzo-2.10/include LIBRARY_PATH=/usr/local/lzo-2.10/lib mvn clean package && \
    apt-get remove -y build-essential maven && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache.log}/ && \
    cd target/native/Linux-amd64-64 && \
    tar -cBf - -C lib . | tar -xBvf - -C /tmp && \
    mkdir -p ${HBASE_INSTALL_DIR}/lib/native && \
    cp /tmp/libgplcompression* ${HBASE_INSTALL_DIR}/lib/native/ && \
    cd /tmp/hadoop-lzo && cp target/hadoop-lzo-0.4.20.jar ${HBASE_INSTALL_DIR}/lib/ && \
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lzo-2.10/lib" >> ${HBASE_INSTALL_DIR}/conf/hbase-env.sh && \
    rm -rf /tmp/lzo-2.10* hadoop-lzo lib libgplcompression*

ADD ./conf/hbase-site.xml /opt/hbase/conf/hbase-site.xml
ADD ./conf/core-site.xml /opt/hbase/conf/core-site.xml
ADD ./conf/hdfs-site.xml /opt/hbase/conf/hdfs-site.xml
ADD ./scripts/entrypoint.sh /opt/hbase/bin/entrypoint.sh
RUN chmod +777 /opt/hbase/bin/entrypoint.sh

WORKDIR ${HBASE_INSTALL_DIR}
RUN echo "export HBASE_JMX_BASE=\"-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false\"" >> conf/hbase-env.sh && \
    echo "export HBASE_MASTER_OPTS=\"\$HBASE_MASTER_OPTS \$HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10101\"" >> conf/hbase-env.sh && \
    echo "export HBASE_REGIONSERVER_OPTS=\"\$HBASE_REGIONSERVER_OPTS \$HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10102\"" >> conf/hbase-env.sh && \
    echo "export HBASE_THRIFT_OPTS=\"\$HBASE_THRIFT_OPTS \$HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10103\"" >> conf/hbase-env.sh && \
    echo "export HBASE_ZOOKEEPER_OPTS=\"\$HBASE_ZOOKEEPER_OPTS \$HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10104\"" >> conf/hbase-env.sh && \
    echo "export HBASE_REST_OPTS=\"\$HBASE_REST_OPTS \$HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10105\"" >> conf/hbase-env.sh

ENV PATH=$PATH:/opt/hbase/bin

CMD /opt/hbase/bin/entrypoint.sh
