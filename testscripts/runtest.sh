#!/bin/bash

#first make sure spring-boot-jdk exists. for example with: docker build -t spring-boot-jdk -f Dockerfile --build-arg JAR_FILE=reactive-rest-service.jar .
#next do docker-compose up before starting this script
#make sure the files / directories from the below variables are reachable

jarfile_reactiverest=reactive-rest-service.jar
soapui_bin=/home/developer/SmartBear/SoapUI-5.4.0/bin
soapui_outputdir=`pwd`/jdktest
soapui_testproject=/home/developer/REST-Project-1-soapui-project.xml

function rebuild() {
	docker stop spring-boot-jdk
	docker rm spring-boot-jdk
	docker rmi spring-boot-jdk
	docker build -t spring-boot-jdk -f Dockerfile --build-arg JAR_FILE=$jarfile_reactiverest .
	docker run -d --name spring-boot-jdk -p 8080:8080 --network complete_dockernet spring-boot-jdk
}

function replacer() {
	var="$@"
	echo STARTING NEW TEST $var
	sed -i "1s/.*/$var/" Dockerfile
}

function get_start_time() {
	docker logs spring-boot-jdk | grep "Started Application"
}

function run_test() {
	echo STARTED AT: `date`
	sleep 5
	mkdir -p /home/developer/jdktest/$1
	$soapui_bin/loadtestrunner.sh -s"TestSuite 1" -c"TestCase 1" -l"LoadTest 0 primer" -r -f$soapui_outputdir/$1 $soapui_testproject  > /dev/null 2>&1
	$soapui_bin/loadtestrunner.sh -s"TestSuite 1" -c"TestCase 1" -l"LoadTest 1" -r -f$soapui_outputdir/$1 $soapui_testproject  > /dev/null 2>&1
	echo COMPLETED AT: `date`
}

docker stop spring-boot-jdk
docker rm spring-boot-jdk
docker rmi spring-boot-jdk
sleep 60

replacer "FROM oracle\/graalvm-ce:1.0.0-rc9"
rebuild
run_test openjdk
get_start_time
sleep 20

replacer "FROM openjdk:8u181"
rebuild
run_test graalvm
get_start_time
sleep 20

replacer "FROM adoptopenjdk\/openjdk8:jdk8u172-b11"
rebuild
run_test adoptopenjdk
get_start_time
sleep 20

replacer "FROM adoptopenjdk\/openjdk8-openj9:jdk8u181-b13_openj9-0.9.0"
rebuild
run_test openj9
get_start_time
sleep 20

replacer "FROM azul\/zulu-openjdk:8u192"
rebuild
run_test zuluopenjdk
get_start_time
sleep 20

replacer "FROM store\/oracle\/serverjre:8"
rebuild
run_test oraclejdk
get_start_time
