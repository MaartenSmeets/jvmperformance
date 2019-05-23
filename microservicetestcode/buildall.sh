export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

cd None
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/noframework-rest-service-1.0-SNAPSHOT.jar ../noframework-rest-service-8.jar
cd ..

cd Quarkus
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/quarkus-rest-service-1.0-SNAPSHOT-runner.jar ../quarkus-rest-service-8.jar
cd ..

cd VertX
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/vertx-rest-service-0.1.0-app.jar ../vertx-rest-service-8.jar
cd ..

cd MicroProfile
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/mp-rest-service.jar ../mp-rest-service-8.jar
cd ..

cd SpringBoot
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/sb-rest-service-0.1.0.jar ../sb-rest-service-8.jar
cd ..

cd SpringBootReactive
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/sb-rest-service-reactive-0.1.0.jar ../sb-rest-service-reactive-8.jar
cd ..

cd SpringFu
./gradlew clean build -Pgraal=true -Dorg.gradle.java.home=$JAVA_HOME
cp build/libs/SpringFu.jar ../sb-rest-service-fu-8.jar
cd ..

cd Akka
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/akka-http-seed-java-1.0-allinone.jar ../akka-rest-service-8.jar
cd ..

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

cd None
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/noframework-rest-service-1.0-SNAPSHOT.jar ../noframework-rest-service-11.jar
cd ..

cd Quarkus
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/quarkus-rest-service-1.0-SNAPSHOT-runner.jar ../quarkus-rest-service-11.jar
cd ..

cd VertX
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/vertx-rest-service-0.1.0-app.jar ../vertx-rest-service-11.jar
cd ..

cd MicroProfile
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/mp-rest-service.jar ../mp-rest-service-11.jar
cd ..

cd SpringBoot
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/sb-rest-service-0.1.0.jar ../sb-rest-service-11.jar
cd ..

cd SpringBootReactive
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/sb-rest-service-reactive-0.1.0.jar ../sb-rest-service-reactive-11.jar
cd ..

cd SpringFu
./gradlew clean build -Pgraal=true -Dorg.gradle.java.home=$JAVA_HOME
cp build/libs/SpringFu.jar ../sb-rest-service-fu-11.jar
cd ..

cd Akka
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/akka-http-seed-java-1.0-allinone.jar ../akka-rest-service-11.jar
cd ..


