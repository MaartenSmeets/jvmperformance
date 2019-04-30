FROM azul/zulu-openjdk:8u202
VOLUME /tmp
ARG JAR_FILE
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx2G","-Xms2G","-jar","/app.jar"]
