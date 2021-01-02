FROM openjdk:11-jdk-slim
LABEL Maintainer="Jyotibikash Panda" Email="jyotibikash07@gmail.com"
ARG SCALA_VERSION="2.13.4"
ARG KAFKA_VERSION="2.13"
ARG "KAFKA_SHORT_VERSION"="2.7.0"
ENV KAFKA_HOME="/opt/kafka/"
RUN  apt-get update \
  && java -version \
  && which java \
  && apt-get install -y wget \
  vim \
  nano \
  tree \
  procps \
  lsof \
  && rm -rf /var/lib/apt/lists/* 
 
RUN apt-get clean && wget https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz -O /tmp/scala-${SCALA_VERSION}.tgz \
    && tar xfz /tmp/scala-${SCALA_VERSION}.tgz -C /opt \
    && rm /tmp/scala-${SCALA_VERSION}.tgz \
    && export SCALA_HOME="/opt/scala-${SCALA_VERSION}" \
    && export PATH="${SCALA_HOME}/bin:$PATH" \
    && scala -version

RUN wget https://downloads.apache.org/kafka/${KAFKA_SHORT_VERSION}/kafka_${KAFKA_VERSION}-${KAFKA_SHORT_VERSION}.tgz -O /opt/kafka_${KAFKA_VERSION}-${KAFKA_SHORT_VERSION}.tgz && \
     tar -xzf /opt/kafka_${KAFKA_VERSION}-${KAFKA_SHORT_VERSION}.tgz -C /opt && \
     ln -s /opt/kafka_${KAFKA_VERSION}-${KAFKA_SHORT_VERSION} /opt/kafka
EXPOSE 2181 9092     
