#!/bin/bash

# 1 make sure spring-boot-jdk exists. for example with: docker build -t spring-boot-jdk -f Dockerfile --build-arg JAR_FILE=reactive-rest-service.jar .
# 2 start process-exporter: docker run -d --rm -p 9256:9256 --privileged -v /proc:/host/proc -v `pwd`/proc-exp:/config ncabatoff/process-exporter --procfs /host/proc -config.path /config/process-exporter.yml 
# for additional information on process exporter see: https://github.com/ncabatoff/process-exporter
# 3 next do docker-compose up
# this starts the containers for monitoring and creates the network
# 4 make sure the files / directories from the below variables are reachable
# 5 start this script

jarfile_reactiverest=`pwd`/reactive-rest-service.jar
soapui_bin=/home/developer/SmartBear/SoapUI-5.4.0/bin
soapui_outputdir=`pwd`/jdktest
soapui_testproject=`pwd`/REST-Project-1-soapui-project.xml

function clean_image() {
	docker stop spring-boot-jdk
	docker rm spring-boot-jdk
	docker rmi spring-boot-jdk
}

function rebuild() {
	clean_image
	docker build -t spring-boot-jdk -f Dockerfile --build-arg JAR_FILE=$jarfile_reactiverest .
	docker run -d --name spring-boot-jdk -p 8080:8080 --network complete_dockernet spring-boot-jdk
}

#update the Dockerfile so it can be rebuild with a new JVM
function replacer() {
	var="$@"
	echo STARTING NEW TEST $var
	sed -i "1s/.*/$var/" Dockerfile
}

#get the spring boot start time
function get_start_time() {
	docker logs spring-boot-jdk | grep "Started Application"
}

#single parameter ndicating the outputdir
function run_test() {
	echo STARTED AT: `date`
	sleep 5
	mkdir -p $soapui_outputdir/$1
	$soapui_bin/loadtestrunner.sh -s"TestSuite 1" -c"TestCase 1" -l"LoadTest 0 primer" -r -f$soapui_outputdir/$1 $soapui_testproject  > /dev/null 2>&1
	$soapui_bin/loadtestrunner.sh -s"TestSuite 1" -c"TestCase 1" -l"LoadTest 1" -r -f$soapui_outputdir/$1 $soapui_testproject  > /dev/null 2>&1
	echo COMPLETED AT: `date`
}

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
