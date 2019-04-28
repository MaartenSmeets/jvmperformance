export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

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

cd SpringFuReactive
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/sb-rest-service-reactive-fu-0.1.0.jar ../sb-rest-service-reactive-fu-8.jar
cd ..

cd SpringFuReactive2
mvn clean package -Dmaven.compiler.source=8 -Dmaven.compiler.target=8
cp target/sb-rest-service-reactive-fu-0.1.0-jar-with-dependencies.jar ../sb-rest-service-reactive-fu2-8.jar
cd ..

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

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

cd SpringFuReactive
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/sb-rest-service-reactive-fu-0.1.0.jar ../sb-rest-service-reactive-fu-11.jar
cd ..

cd SpringFuReactive2
mvn clean package -Dmaven.compiler.source=11 -Dmaven.compiler.target=11
cp target/sb-rest-service-reactive-fu-0.1.0-jar-with-dependencies.jar ../sb-rest-service-reactive-fu2-11.jar
cd ..
