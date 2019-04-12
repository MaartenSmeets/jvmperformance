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
soapui_testproject=$DIR/REST-Project-1-soapui-project_1h.xml

function clean_image() {
	docker stop spring-boot-jdk
	docker rm spring-boot-jdk
	docker rmi spring-boot-jdk
}

function rebuild() {
	clean_image
	docker build -t spring-boot-jdk -f Dockerfile_local --build-arg JAR_FILE=$jarfile_reactiverest .
	docker run -d --name spring-boot-jdk -p 8080:8080 --network testscripts_dockernet spring-boot-jdk
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
    	echo REQUESTS PROCESSED: `awk -F, 'NR == 3 { print $6 }' $soapui_outputdir/$1/LoadTest_1-statistics.txt`
}

for i in {1..5}
do
echo EXECUTING RUN $i
rebuild
run_test openjdk_docker_$i
get_start_time
docker stop spring-boot-jdk

/usr/lib/jvm/java-8-openjdk-amd64/bin/java -Djava.security.egd=file:/dev/./urandom -XX:+UnlockExperimentalVMOptions -Xmx2G -Xms2G -jar ./reactive-rest-service.jar | grep "Started Application" &
run_test openjdk_local_$i
killall java
done









