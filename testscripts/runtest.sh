#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
echo Running from $DIR

jarfilelist8=("noframework-rest-service-8.jar" "mp-rest-service-8.jar" "sb-rest-service-8.jar" "sb-rest-service-reactive-8.jar" "sb-rest-service-fu-8.jar" "vertx-rest-service-8.jar" "akka-rest-service-8.jar" "quarkus-rest-service-8.jar")

test_outputdir8=$DIR/$1/jdktest_8_`date +"%Y%m%d%H%M%S"`

jarfilelist11=("noframework-rest-service-11.jar" "mp-rest-service-11.jar" "sb-rest-service-11.jar" "sb-rest-service-reactive-11.jar" "sb-rest-service-fu-11.jar" "vertx-rest-service-11.jar" "akka-rest-service-11.jar" "quarkus-rest-service-11.jar")
test_outputdir11=$DIR/$1/jdktest_11_`date +"%Y%m%d%H%M%S"`
indicator=("_none" "_mp" "_sb" "_sbreactive" "_sbfu" "_vertx" "_akka" "_qs")
combined=( "${jarfilelist8[@]}" "${jarfilelist11[@]}" )
for f in "${combined[@]}" ; do 
    if [ -f "$f" ]; then
        echo "$f: found"
    else
        echo "$f: not found"
        exit 0
    fi
done 

loadgenduration=300
echo Isolated CPUs `cat /sys/devices/system/cpu/isolated`
cpulistperftest=4,5,6,7
cpulistjava=8,9,10,11
stoptimeout=180

echo CPUs used for Performance test $cpulistperftest
echo CPUs used for Java process $cpulistjava

function init() {
git checkout -- Dockerfile
docker stop -t $stoptimeout perftest > /dev/null 2>&1
docker rm perftest > /dev/null 2>&1
docker stop spring-boot-jdk > /dev/null 2>&1
docker rm spring-boot-jdk > /dev/null 2>&1
docker rmi spring-boot-jdk > /dev/null 2>&1
docker-compose stop > /dev/null 2>&1
docker-compose rm -f > /dev/null 2>&1
docker-compose up -d > /dev/null 2>&1
}

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
    docker run --cpuset-cpus $cpulistjava -d --name spring-boot-jdk -p 8080:8080 --network testscripts_dockernet --device /dev/zing_mm0:/dev/zing_mm0 spring-boot-jdk
    export mypid=`ps -o pid,sess,cmd afx | egrep "( |/)java.*app.jar.*( -f)?$" | awk '{print $1}'`
    if [ -z "$mypid" ]; then
        echo No PID found so no taskset
    else
        echo Java process PID: $mypid setting CPU affinity to $cpulistjava
        sudo taskset -pc $cpulistjava $mypid
        #give it some time to startup
        sleep 60
    fi 
}

#SetJVMParams
function setjvmparams() {
    var="$@"
    echo REPLACE LINE WITH $var
    sed -i '$ d' Dockerfile
    echo $var >> Dockerfile
}

#update the Dockerfile so it can be rebuild with a new JVM
function replacer() {
	var="$@"
	echo STARTING NEW TEST $var
	sed -i "1s/.*/$var/" Dockerfile
}

#get the start time
function get_start_time() {
    echo $1 `docker logs spring-boot-jdk | grep "STARTED Controller started" | tail -1`
    echo $1 `docker logs spring-boot-jdk | grep "STARTED Application started" | tail -1`
}

function start_loadgen() {
    mkdir $2/logs
    mygroup=`groups | awk '{print $1}'`
    if [ -e "/dev/zing_mm0" ]; then
        docker run -u `id -u`:`id -g $mygroup` -v $2/logs:/logs --cpuset-cpus $cpulistperftest -d --name perftest --network testscripts_dockernet -e URL=$1 -e LOGFILEDIR=/logs --device /dev/zing_mm0:/dev/zing_mm0 perftest
    else
        docker run -u `id -u`:`id -g $mygroup` -v $2/logs:/logs --cpuset-cpus $cpulistperftest -d --name perftest --network testscripts_dockernet -e URL=$1 -e LOGFILEDIR=/logs perftest
    fi
    for mypid in `ps -e -o pid,comm,cgroup | grep "/docker/${cid}" | awk '$2=="python" || $2=="node" {print $1}'`
    do
        echo Setting CPU affinity for $mypid to $cpulistperftest       
        taskset -a -cp $cpulistperftest $mypid
    done
    sleep $3
    #docker exec --user node perftest "/bin/sh" -c "cat /home/node/app/*.log > /home/node/app/combined.log"
    #docker cp perftest:/home/node/app/combined.log $2
    docker stop -t $stoptimeout perftest
    docker rm perftest
    cat $2/logs/*.log > $2/results.txt
    if [ -f $2/results.txt ]; then
        rm $2/logs/*.log
        rmdir $2/logs
    fi
}

function get_prom_stats_sb() {
    echo $1 Starting get prom stats from $2
    PROM_REQUESTS=`wget -qO- $2 | egrep 'http_server_requests_seconds_count.*status\=\"200\",\uri\=\"\/greeting' | awk '{print $2}'`
    PROM_TOTALTIME_S=`wget -qO- $2 | egrep 'http_server_requests_seconds_sum.*status\=\"200\",\uri\=\"\/greeting' | awk '{print $2}'`
    PROM_AVERAGE_MS=`awk "BEGIN {printf \"%.5f\n\", 1000*$PROM_TOTALTIME_S/$PROM_REQUESTS}"`
    echo $1 PROM_REQUESTS: $PROM_REQUESTS
    echo $1 PROM_TOTALTIME_S: $PROM_TOTALTIME_S
    echo $1 PROM_AVERAGE_MS: $PROM_AVERAGE_MS
}

function get_prom_stats_vertx() {
    echo $1 Starting get prom stats from $2
    PROM_REQUESTS=`wget -qO- $2 | egrep 'http_server_responseTime_seconds_count.*code\=\"200\",\path\=\"\/greeting' | awk '{print $2}'`
    PROM_TOTALTIME_S=`wget -qO- $2 | egrep 'http_server_responseTime_seconds_sum.*code\=\"200\",\path\=\"\/greeting' | awk '{print $2}'`
    PROM_AVERAGE_MS=`awk "BEGIN {printf \"%.5f\n\", 1000*$PROM_TOTALTIME_S/$PROM_REQUESTS}"`
    echo $1 PROM_REQUESTS: $PROM_REQUESTS
    echo $1 PROM_TOTALTIME_S: $PROM_TOTALTIME_S
    echo $1 PROM_AVERAGE_MS: $PROM_AVERAGE_MS
}

function get_prom_stats_mp() {
    echo $1 Starting get prom stats from $2
    PROM_AVERAGE_S=`wget -qO- $2 | egrep '^application:messages_processed_mean_seconds' | awk '{print $2}'`
    PROM_AVERAGE_MS=`awk "BEGIN {printf \"%.5f\n\", 1000*$PROM_AVERAGE_S}"`
    PROM_REQUESTS=`wget -qO- $2 | egrep '^application:messages_processed_seconds_count' | awk '{print $2}'`
    PROM_TOTALTIME_S=`awk "BEGIN {printf \"%.5f\n\", $PROM_AVERAGE_S*$PROM_REQUESTS}"`
    echo $1 PROM_REQUESTS: $PROM_REQUESTS
    echo $1 PROM_TOTALTIME_S: $PROM_TOTALTIME_S
    echo $1 PROM_AVERAGE_MS: $PROM_AVERAGE_MS
}

function check_sb_prom() {
    return `wget -qO- http://localhost:8080/prometheus | egrep 'http_server_requests_seconds_count.*status\=\"200\",\uri\=\"\/greeting' | wc -l`
}

function check_vertx_prom() {
    return `wget -qO- http://localhost:8080/metrics | egrep 'http_server_responseTime_seconds_count.*code\=\"200\",\path\=\"\/greeting' | wc -l`
}

function check_mp_prom() {
    return `wget -qO- http://localhost:8080/metrics | egrep '^application:messages_processed_seconds_count' | wc -l`
}

#single parameter indicating the outputdir
function run_test() {
    echo $1 STARTED AT: `date`
    mkdir -p $test_outputdir/$1
    start_loadgen http://spring-boot-jdk:8080/greeting?name=Maarten $test_outputdir/$1 $loadgenduration
    check_sb_prom
    valResult=$?
    if [[ $valResult -gt 0 ]] 
    then   
        get_prom_stats_sb $1 http://localhost:8080/prometheus
    else
        echo $1 No Spring Boot Prometheus available
    fi
    check_mp_prom
    valResult=$?
    if [[ $valResult -gt 0 ]] 
    then
        get_prom_stats_mp $1 http://localhost:8080/metrics
    else
        echo $1 No MicroProfile Prometheus available
    fi
    check_vertx_prom
    valResult=$?
    if [[ $valResult -gt 0 ]] 
    then
        get_prom_stats_vertx $1 http://localhost:8080/metrics
    else
        echo $1 No Vert.X Prometheus available
    fi

    echo $1 COMPLETED_AT: `date`
    echo $1 REQUESTS_PROCESSED: `cat $test_outputdir/$1/results.txt | grep MEASURE | wc -l`
    echo $1 AVERAGE_PROCESSING_TIME_MS: `cat $test_outputdir/$1/results.txt | grep MEASURE | awk -F " " '{ total += $3 } END { print total/NR }'`
    echo $1 STANDARD_DEVIATION_MS: `cat $test_outputdir/$1/results.txt | grep MEASURE | awk '{delta = $3 - avg; avg += delta / NR; mean2 += delta * ($3 - avg); } END { print sqrt(mean2 / NR); }'`
}

jarfilelist=${jarfilelist8[@]}
test_outputdir=$test_outputdir8

echo Redirecting output to $test_outputdir
mkdir -p $test_outputdir
exec > $test_outputdir/outputfile.txt
exec 2>&1
echo Initializing: cleaning up
init

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
ind=${indicator[$counter]}
if [ "$ind" == "_qs" ]; then
    rm Dockerfile.orig
    mv Dockerfile Dockerfile.orig
    cp Dockerfile.native Dockerfile
    setjvmparams 'ENTRYPOINT ["./application", "-Dquarkus.http.host=0.0.0.0", "-Xmx25m", "-Xms25m"]'
    clean_image
    docker build -t spring-boot-jdk -f Dockerfile .
    docker run --cpuset-cpus $cpulistjava -d --name spring-boot-jdk -p 8080:8080 --network testscripts_dockernet --device /dev/zing_mm0:/dev/zing_mm0 spring-boot-jdk
    #give it some time to startup
    sleep 60
    run_test native_qs
    get_start_time native_qs
    sleep 20
    rm Dockerfile
    mv Dockerfile.orig Dockerfile
elif [ "$ind" == "_none" ]; then
    rm Dockerfile.orig
    mv Dockerfile Dockerfile.orig
    cp Dockerfile.native.none Dockerfile
    setjvmparams 'ENTRYPOINT ["./application"]'
    clean_image
    docker build -t spring-boot-jdk -f Dockerfile .
    docker run --cpuset-cpus $cpulistjava -d --name spring-boot-jdk -p 8080:8080 --network testscripts_dockernet --device /dev/zing_mm0:/dev/zing_mm0 spring-boot-jdk
    #give it some time to startup
    sleep 60
    run_test native_none
    get_start_time native_none
    sleep 20
    rm Dockerfile
    mv Dockerfile.orig Dockerfile
else
    echo native${ind} AVERAGE_PROCESSING_TIME_MS: 0
    echo native${ind} STANDARD_DEVIATION_MS: 0
    if [ "$ind" == "_sb" ]; then
        echo native${ind} STARTED Application started: 0
    fi
    if [ "$ind" == "_sbreactive" ]; then
        echo native${ind} STARTED Application started: 0
    fi
fi
done

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
rm Dockerfile.orig
mv Dockerfile Dockerfile.orig
cp Dockerfile.zing8 Dockerfile
setjvmparams 'ENTRYPOINT ["/opt/zing/zing-jdk8/bin/java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]'
rebuild $jarfilename
run_test zing${indicator[$counter]}
get_start_time zing${indicator[$counter]}
sleep 20
rm Dockerfile
mv Dockerfile.orig Dockerfile
done

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM adoptopenjdk\/openjdk8:jdk8u202-b08"
setjvmparams 'ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]'
rebuild $jarfilename
run_test adoptopenjdk${indicator[$counter]}
get_start_time adoptopenjdk${indicator[$counter]}
sleep 20
done

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM adoptopenjdk\/openjdk8-openj9:jdk8u202-b08_openj9-0.12.1"
setjvmparams 'ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]'
rebuild $jarfilename
run_test openj9${indicator[$counter]}
get_start_time openj9${indicator[$counter]}
sleep 20
done

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM store\/oracle\/serverjre:8"
setjvmparams 'ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]'
rebuild $jarfilename
run_test oraclejdk${indicator[$counter]}
get_start_time oraclejdk${indicator[$counter]}
sleep 20
done

jarfilelist=${jarfilelist11[@]}
test_outputdir=$test_outputdir11

echo Redirecting output to $test_outputdir
mkdir -p $test_outputdir
exec > $test_outputdir/outputfile.txt
exec 2>&1
echo Initializing: cleaning up
init

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
rm Dockerfile.orig
mv Dockerfile Dockerfile.orig
cp Dockerfile.zing11 Dockerfile
setjvmparams 'ENTRYPOINT ["/opt/zing/zing-jdk11/bin/java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]'
rebuild $jarfilename
run_test zing${indicator[$counter]}
get_start_time zing${indicator[$counter]}
sleep 20
rm Dockerfile
mv Dockerfile.orig Dockerfile
done

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
rm Dockerfile.orig
mv Dockerfile Dockerfile.orig
cp Dockerfile.ojdk11 Dockerfile
setjvmparams 'ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]'
rebuild $jarfilename
run_test oraclejdk${indicator[$counter]}
get_start_time oraclejdk${indicator[$counter]}
sleep 20
rm Dockerfile
mv Dockerfile.orig Dockerfile
done

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM adoptopenjdk\/openjdk11-openj9:jdk-11.0.3.7_openj9-0.14.0"
setjvmparams 'ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]'
rebuild $jarfilename
run_test openj9${indicator[$counter]}
get_start_time openj9${indicator[$counter]}
sleep 20
done

counter=-1
for jarfilename in ${jarfilelist[@]}
do
counter=$(( $counter + 1 ))
replacer "FROM adoptopenjdk\/openjdk11:jdk-11.0.3.7"
setjvmparams 'ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-XX:+UnlockExperimentalVMOptions","-Xmx25m","-Xms25m","-jar","/app.jar"]'
rebuild $jarfilename
run_test adoptopenjdk${indicator[$counter]}
get_start_time adoptopenjdk${indicator[$counter]}
sleep 20
done
