#!/bin/bash

# 1 make sure you have a new version of docker-compose, for example version 1.23.2. 1.21.0 doesn't work with the docker-compose.yml file
# 2 start process-exporter: docker run -d --rm -p 9256:9256 --privileged -v /proc:/host/proc -v `pwd`/proc-exp:/config ncabatoff/process-exporter --procfs /host/proc -config.path /config/process-exporter.yml 
# for additional information on process exporter see: https://github.com/ncabatoff/process-exporter
# 3 next do docker-compose up -d
# this starts the containers for monitoring and creates the network
# 4 make sure node is installed and npm install has been executed in the directory of client.js
# 5 start this script

#Mind that the below line requires the bash shell
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo Running from $DIR

jarfilelist=("mp-rest-service-8.jar" "sb-rest-service-8.jar" "sb-rest-service-reactive-8.jar" "sb-rest-service-reactive-fu-8.jar")
test_outputdir=$DIR/jdktest`date +"%Y%m%d%H%M%S"`
primerduration=30
loadgenduration=300

echo Redirecting output to $test_outputdir
mkdir -p $test_outputdir
exec > $test_outputdir/outputfile.txt
exec 2>&1

function clean_image() {
	docker stop spring-boot-jdk
	docker rm spring-boot-jdk
	docker rmi spring-boot-jdk
}

function rebuild() {
    clean_image
    var="$@"
    echo USING JARFILE: $var
    docker build -t spring-boot-jdk -f Dockerfile --build-arg JAR_FILE=$var .
    docker run -d --name spring-boot-jdk -p 8080:8080 --network testscripts_dockernet spring-boot-jdk
    export mypid=`ps -o pid,sess,cmd afx | egrep "( |/)java.*app.jar.*( -f)?$" | awk '{print $1}'`
    echo Java process PID: $mypid setting CPU affinity
    sudo taskset -pc 5,6,7,8 $mypid
    #give it some time to startup
    sleep 10
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

function start_primer() {
    var="$@"
    taskset -c 1,2,3,4 node ../nodejsperftest/client.js > $var &
    pid=$!
    sleep $primerduration
    kill $pid
}

function start_loadgen() {
    var="$@"
    taskset -c 1,2,3,4 node ../nodejsperftest/client.js > $var &
    pid=$!
    sleep $loadgenduration
    kill $pid
}

#single parameter indicating the outputdir
function run_test() {
    echo $1 STARTED AT: `date`
    mkdir -p $test_outputdir/$1
    start_primer $test_outputdir/$1/primer.txt
    start_loadgen $test_outputdir/$1/results.txt
    echo $1 COMPLETED AT: `date`
    echo $1 REQUESTS PROCESSED: `cat $test_outputdir/$1/results.txt | grep MEASURE | wc -l`
    echo $1 AVERAGE PROCESSING TIME: `cat $test_outputdir/$1/results.txt | grep MEASURE | awk -F " " '{ total += $2 } END { print total/NR }'`
    #SOAPUI resultfile parsing: echo REQUESTS PROCESSED: `awk -F, 'NR == 3 { print $6 }' $soapui_outputdir/$1/LoadTest_1-statistics.txt`
}

for jarfilename in ${jarfilelist[@]}
do
replacer "FROM oracle\/graalvm-ce:1.0.0-rc14"
rebuild $jarfilename
run_test graalvm
get_start_time
sleep 20
done

for jarfilename in ${jarfilelist[@]}
do
replacer "FROM adoptopenjdk\/openjdk8:jdk8u202-b08"
rebuild $jarfilename
run_test adoptopenjdk
get_start_time
sleep 20
done

for jarfilename in ${jarfilelist[@]}
do
replacer "FROM adoptopenjdk\/openjdk8-openj9:jdk8u202-b08_openj9-0.12.1"
rebuild $jarfilename
run_test openj9
get_start_time
sleep 20
done

for jarfilename in ${jarfilelist[@]}
do
replacer "FROM azul\/zulu-openjdk:8u202"
rebuild $jarfilename
run_test zuluopenjdk
get_start_time
sleep 20
done

for jarfilename in ${jarfilelist[@]}
do
replacer "FROM store\/oracle\/serverjre:8"
rebuild $jarfilename
run_test oraclejdk
get_start_time
sleep 20
done
