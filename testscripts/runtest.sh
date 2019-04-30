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

jarfilelist=("mp-rest-service-8.jar" "sb-rest-service-8.jar" "sb-rest-service-reactive-8.jar" "sb-rest-service-reactive-fu-8.jar" "sb-rest-service-reactive-fu2-8.jar")
#jarfilelist=("mp-rest-service-8.jar")
test_outputdir=$DIR/jdktest`date +"%Y%m%d%H%M%S"`
primerduration=10
loadgenduration=10
echo Isolated CPUs `cat /sys/devices/system/cpu/isolated`
cpulistperftest=4,5,6,7
cpulistjava=8,9,10,11

echo CPUs used for Performance test $cpulistperftest
echo CPUs used for Java process $cpulistjava


function init() {
docker stop perftest > /dev/null 2>&1
docker rm perftest > /dev/null 2>&1
docker stop spring-boot-jdk > /dev/null 2>&1
docker rm spring-boot-jdk > /dev/null 2>&1
docker rmi spring-boot-jdk > /dev/null 2>&1
docker-compose stop > /dev/null 2>&1
docker-compose rm -f > /dev/null 2>&1
docker-compose up -d > /dev/null 2>&1
}

echo Initializing: cleaning up, starting Prometheus and Grafana
init
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
    echo Java process PID: $mypid setting CPU affinity to $cpulistjava
    sudo taskset -pc $cpulistjava $mypid
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
	docker logs spring-boot-jdk | grep "STARTED Controller started"
        docker logs spring-boot-jdk | grep "STARTED Application started"
}

function start_loadgen() {
    docker run -d --name perftest --network testscripts_dockernet -e URL=$1 perftest
    for mypid in `ps -e -o pid,comm,cgroup | grep "/docker/${cid}" | awk '$2=="node" {print $1}'`
    do
        echo Setting CPU affinity for $mypid to $cpulistperftest       
        taskset -a -cp $cpulistperftest $mypid
    done
    sleep $3
    docker exec --user node perftest "/bin/sh" -c "cat /home/node/app/*.log > /home/node/app/combined.log"
    docker cp perftest:/home/node/app/combined.log $2
    docker stop perftest
    docker rm perftest
}

#single parameter indicating the outputdir
function run_test() {
    echo $1 STARTED AT: `date`
    mkdir -p $test_outputdir/$1
    start_loadgen http://spring-boot-jdk:8080/greeting?name=Maarten $test_outputdir/$1/primer.txt $primerduration
    start_loadgen http://spring-boot-jdk:8080/greeting?name=Maarten $test_outputdir/$1/results.txt $loadgenduration
    echo $1 COMPLETED AT: `date`
    echo $1 REQUESTS PROCESSED: `cat $test_outputdir/$1/results.txt | grep MEASURE | wc -l`
    echo $1 AVERAGE PROCESSING TIME: `cat $test_outputdir/$1/results.txt | grep MEASURE | awk -F " " '{ total += $2 } END { print total/NR }'`
    #SOAPUI resultfile parsing: echo REQUESTS PROCESSED: `awk -F, 'NR == 3 { print $6 }' $soapui_outputdir/$1/LoadTest_1-statistics.txt`
}

counter=0
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM oracle\/graalvm-ce:1.0.0-rc16"
rebuild $jarfilename
run_test graalvm$counter
get_start_time
sleep 20
done

counter=0
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM adoptopenjdk\/openjdk8:jdk8u202-b08"
rebuild $jarfilename
run_test adoptopenjdk$counter
get_start_time
sleep 20
done

counter=0
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM adoptopenjdk\/openjdk8-openj9:jdk8u202-b08_openj9-0.12.1"
rebuild $jarfilename
run_test openj9$counter
get_start_time
sleep 20
done

counter=0
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM azul\/zulu-openjdk:8u202"
rebuild $jarfilename
run_test zuluopenjdk$counter
get_start_time
sleep 20
done

counter=0
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM store\/oracle\/serverjre:8"
rebuild $jarfilename
run_test oraclejdk$counter
get_start_time
sleep 20
done
