#!/bin/bash

# 1 make sure you have a new version of docker-compose, for example version 1.23.2. 1.21.0 doesn't work with the docker-compose.yml file
# 2 start process-exporter: docker run -d --rm -p 9256:9256 --privileged -v /proc:/host/proc -v `pwd`/proc-exp:/config ncabatoff/process-exporter --procfs /host/proc -config.path /config/process-exporter.yml 
# for additional information on process exporter see: https://github.com/ncabatoff/process-exporter
# 3 next do docker-compose up
# this starts the containers for monitoring and creates the network
# 4 make sure the files / directories from the below variables are reachable and you have SOAP UI installed
# 5 start this script

#Mind that the below line requires the bash shell
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo Running from $DIR

jarfile_reactiverest=reactive-rest-service.jar
soapui_bin=/home/maarten/SmartBear/SoapUI-5.5.0/bin
soapui_outputdir=$DIR/jdktest`date +"%Y%m%d%H%M%S"`
soapui_testproject=$DIR/REST-Project-1-soapui-project_10m.xml

function clean_image() {
	docker stop spring-boot-jdk
	docker rm spring-boot-jdk
	docker rmi spring-boot-jdk
}

function rebuild() {
	clean_image
	docker build -t spring-boot-jdk -f Dockerfile --build-arg JAR_FILE=$jarfile_reactiverest .
	docker run -d --name spring-boot-jdk -p 8080:8080 --network testscripts_dockernet spring-boot-jdk
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
    	echo REQUESTS PROCESSED: $1 `awk -F, 'NR == 3 { print $6 }' $soapui_outputdir/$1/LoadTest_1-statistics.txt`
}

replacer "FROM adoptopenjdk\/openjdk8:jdk8u202-b08"
rebuild
run_test openjdk
echo openjdk: $(get_start_time)

for i in {13..15}
do
replacer "FROM oracle\/graalvm-ce:1.0.0-rc$i"
rebuild
run_test graalvm$i
echo graalvm$i: $(get_start_time)
sleep 20
done

replacer "FROM adoptopenjdk\/openjdk8:jdk8u202-b08"
rebuild
run_test adoptopenjdk
echo adoptopenjdk: $(get_start_time)
sleep 20

replacer "FROM adoptopenjdk\/openjdk8-openj9:jdk8u202-b08_openj9-0.12.1"
rebuild
run_test openj9
echo openj9: $(get_start_time)
sleep 20

replacer "FROM azul\/zulu-openjdk:8u202"
rebuild
run_test zuluopenjdk
echo zuluopenjdk: $(get_start_time)
sleep 20

replacer "FROM store\/oracle\/serverjre:8"
rebuild
run_test oraclejdk
echo oraclejdk: $(get_start_time)
sleep 20

replacer "FROM adoptopenjdk\/openjdk8:jdk8u202-b08"
rebuild
run_test openjdk
echo openjdk: $(get_start_time)
