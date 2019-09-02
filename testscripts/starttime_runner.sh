#!/bin/bash
#Based on https://askubuntu.com/questions/1080113/measuring-execution-time-of-a-command-in-milliseconds

java8cmd="/usr/lib/jvm/java-8-openjdk-amd64/bin/java -Xmx1024m -Xms1024m -XX:+UseG1GC -XX:+UseStringDeduplication -jar"
java11cmd="/usr/lib/jvm/java-11-openjdk-amd64/bin/java -Xmx1024m -Xms1024m -XX:+UseG1GC -XX:+UseStringDeduplication -jar"
javaopenj9222="/home/maarten/Downloads/jdk8u222-b10/bin/java -Xmx1024m -Xms1024m -Xshareclasses:name=Cache1 -jar"
javaoracle8221="/home/maarten/Downloads/jdk1.8.0_221/bin/java -Xmx1024m -Xms1024m -XX:+UseG1GC -XX:+UseStringDeduplication -jar"
#javazing="/opt/zing/zing-jdk1.8.0-19.08.0.0-5/bin/java -XX:+FalconUseCompileStashing -XX:+FalconSaveObjectCache -XX:ProfileLogOut=MyApp.prof -Xmx1024m -Xms1024m -jar"
javazing="/opt/zing/zing-jdk1.8.0-19.08.0.0-5/bin/java -XX:+FalconUseCompileStashing -XX:+FalconLoadObjectCache -XX:ProfileLogOut=MyApp.prof -XX:ProfileLogIn=MyApp.prof -Xmx1024m -Xms1024m -jar"

stopcommand=("WEB server is up!" "Startup completed in" "server is ready to run a smarter planet" "JVM running for" "JVM running for" "JVM running for" "Succeeded in deploying verticle" "Server online at" "started in" "STARTED Application started")

prefix=("hse" "mn" "mp" "sb" "sbreactive" "sbfu" "vertx" "akka" "qs" "no")
jarlist8=("helidon-rest-service-8.jar" "micronaut-rest-service-8.jar" "mp-rest-service-8.jar" "sb-rest-service-8.jar" "sb-rest-service-reactive-8.jar" "sb-rest-service-fu-8.jar" "vertx-rest-service-8.jar" "akka-rest-service-8.jar" "quarkus-rest-service-8.jar" "noframework-rest-service-8.jar")
jarlist11=("helidon-rest-service-11.jar" "micronaut-rest-service-11.jar" "mp-rest-service-11.jar" "sb-rest-service-11.jar" "sb-rest-service-reactive-11.jar" "sb-rest-service-fu-11.jar" "vertx-rest-service-11.jar" "akka-rest-service-11.jar" "quarkus-rest-service-11.jar" "noframework-rest-service-11.jar")

nativefilelist=("./helidon-rest-service" "./micronaut-native" "./quarkus-rest-service-1.0-SNAPSHOT-runner" "./noframework-rest-service-8")
nativeprefix=("hse" "mn" "qs" "no")
nativestopcommand=("WEB server is up!" "Startup completed in" "started in" "STARTED Application started")


test_outputfile=starttime_`date +"%Y%m%d%H%M%S"`.log
runsize=1000

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
    rm -rf ~/wlpExtract
    ts=$(date +%s%N)
    #Based on https://superuser.com/questions/402979/kill-program-after-it-outputs-a-given-line-from-a-shell-script
    timelimit -t100 expect -c "spawn $1 -jar $3; expect \"$4\" { close }" > /dev/null 2>&1
    echo $5,$2,$((($(date +%s%N) - $ts)/1000000)) >> $test_outputfile
    killall -9 java
    done
}

function execute_test_native() {
    #first parameter is the command, second the java version, third the stop command, fourth the prefix
    for (( c=1; c<=$runsize; c++ ))
    do
    rm -rf ~/wlpExtract
    ts=$(date +%s%N)
    #Based on https://superuser.com/questions/402979/kill-program-after-it-outputs-a-given-line-from-a-shell-script
    timelimit -t100 expect -c "spawn $1; expect \"$3\" { close }" > /dev/null 2>&1
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
execute_test "$java8cmd" 8openjdk $jarfilename "$scmd" $ind
done

echo Executing test for Java 8 OpenJ9
counter=-1
for jarfilename in ${jarlist8[@]}
do
echo Processing $jarfilename
counter=$(( $counter + 1 ))
ind=${prefix[$counter]}
scmd=${stopcommand[$counter]}
execute_test "$javaopenj9222" 8openj9 $jarfilename "$scmd" $ind
done

echo Executing test for Java 8 Oracle
counter=-1
for jarfilename in ${jarlist8[@]}
do
echo Processing $jarfilename
counter=$(( $counter + 1 ))
ind=${prefix[$counter]}
scmd=${stopcommand[$counter]}
execute_test "$javaoracle8221" 8oracle $jarfilename "$scmd" $ind
done

echo Executing test for Java 8 Zing
counter=-1
for jarfilename in ${jarlist8[@]}
do
echo Processing $jarfilename
counter=$(( $counter + 1 ))
ind=${prefix[$counter]}
scmd=${stopcommand[$counter]}
execute_test "$javazing" 8zing $jarfilename "$scmd" $ind
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
execute_test_native "$execcmd" "svm" "$scmd" $ind
done

