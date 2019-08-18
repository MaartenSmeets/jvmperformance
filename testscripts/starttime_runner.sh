#!/bin/bash
#Based on https://askubuntu.com/questions/1080113/measuring-execution-time-of-a-command-in-milliseconds

java8cmd="/usr/lib/jvm/java-8-openjdk-amd64/bin/java -Xmx1024m -Xms1024m -XX:+UseG1GC -XX:+UseStringDeduplication -jar"
java11cmd="/usr/lib/jvm/java-11-openjdk-amd64/bin/java -Xmx1024m -Xms1024m -XX:+UseG1GC -XX:+UseStringDeduplication -jar"

stopcommand=("WEB server is up!" "Startup completed in" "server is ready to run a smarter planet" "JVM running for" "JVM running for" "JVM running for" "Succeeded in deploying verticle" "Server online at" "started in")

prefix=("hse" "mn" "mp" "sb" "sbreactive" "sbfu" "vertx" "akka" "qs")
jarlist8=("helidon-rest-service-8.jar" "micronaut-rest-service-8.jar" "mp-rest-service-8.jar" "sb-rest-service-8.jar" "sb-rest-service-reactive-8.jar" "sb-rest-service-fu-8.jar" "vertx-rest-service-8.jar" "akka-rest-service-8.jar" "quarkus-rest-service-8.jar")
jarlist11=("helidon-rest-service-11.jar" "micronaut-rest-service-11.jar" "mp-rest-service-11.jar" "sb-rest-service-11.jar" "sb-rest-service-reactive-11.jar" "sb-rest-service-fu-11.jar" "vertx-rest-service-11.jar" "akka-rest-service-11.jar" "quarkus-rest-service-11.jar")

nativefilelist=("./helidon-rest-service" "./micronaut-native" "./quarkus-rest-service-1.0-SNAPSHOT-runner")
nativeprefix=("hse" "mn" "qs")
nativestopcommand=("WEB server is up!" "Startup completed in" "started in")

test_outputfile=starttime_`date +"%Y%m%d%H%M%S"`.log
runsize=100

function check_files() {
    combined=( "${jarlist8[@]}" "${jarlist11[@]}" "${nativefilelist[@]}")
    for f in "${combined[@]}" ; do 
        if [ -f "$f" ]; then
            echo "$f: found"
        else
            echo "$f: not found"
            exit 0
        fi
    done 
}

function execute_test() {
    #first parameter is the java command, second the java version, third the jar and fourth the stop command, fifth the prefix
    for (( c=1; c<=$runsize; c++ ))
    do
    ts=$(date +%s%N)
    #Based on https://superuser.com/questions/402979/kill-program-after-it-outputs-a-given-line-from-a-shell-script
    expect -c "spawn $1 -jar $3; expect \"$4\" { close }" > /dev/null 2>&1
    echo $5,$2,$((($(date +%s%N) - $ts)/1000000)) >> $test_outputfile
    done
}

function execute_test_native() {
    #first parameter is the command, second the java version, third the stop command, fourth the prefix
    for (( c=1; c<=$runsize; c++ ))
    do
    ts=$(date +%s%N)
    #Based on https://superuser.com/questions/402979/kill-program-after-it-outputs-a-given-line-from-a-shell-script
    expect -c "spawn $1; expect \"$3\" { close }" > /dev/null 2>&1
    echo $4,$2,$((($(date +%s%N) - $ts)/1000000)) >> $test_outputfile
    done
}


echo Checking files
check_files

echo Executing test for Java 8
counter=-1
for jarfilename in ${jarlist8[@]}
do
echo Processing $jarfilename
counter=$(( $counter + 1 ))
ind=${prefix[$counter]}
scmd=${stopcommand[$counter]}
execute_test "$java8cmd" 8 $jarfilename "$scmd" $ind
done

echo Executing test for Java 11
counter=-1
for jarfilename in ${jarlist11[@]}
do
echo Processing $jarfilename
counter=$(( $counter + 1 ))
ind=${prefix[$counter]}
scmd=${stopcommand[$counter]}
execute_test "$java11cmd" 11 $jarfilename "$scmd" $ind
done

echo Executing test for Native
counter=-1
for execcmd in ${nativefilelist[@]}
do
echo Processing $execcmd
counter=$(( $counter + 1 ))
ind=${nativeprefix[$counter]}
scmd=${nativestopcommand[$counter]}
execute_test_native $execcmd "svm" "$scmd" $ind
done

