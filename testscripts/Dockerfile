FROM ubuntu:16.04

RUN apt-get update -y
RUN apt-get install -y software-properties-common python-software-properties
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
RUN /usr/bin/apt-add-repository "deb http://repos.azul.com/zing/ubuntu-container $(lsb_release -sc) main"
RUN apt-get update -y
RUN apt-get install zing-jdk1.8.0 -y
ENV LANG en_US.utf8
ENV J2SDKDIR /opt/zing/zing-jdk8
ENV J2REDIR /opt/zing/zing-jdk8
ENV PATH "${PATH}:/opt/zing/zing-jdk8/bin"
ENV JAVA_HOME /opt/zing/zing-jdk8
WORKDIR /temp
ADD ./license /etc/zing/
VOLUME /tmp
ARG JAR_FILE
COPY ${JAR_FILE} /app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]
