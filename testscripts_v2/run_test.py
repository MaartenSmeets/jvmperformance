import os.path
import logging
import subprocess
import os, signal
import time
import re
from datetime import datetime

test_duration=10
primer_duration=1
wait_after_primer=1
wait_to_start=10
wait_after_kill=2
now = datetime.now()
datestring=now.strftime("%Y%m%d_%H%M%S")
resultsfile='results_'+datestring+'.log'
outputfile='output_'+datestring+'.log'

logger = logging.getLogger('run_test')
logger.setLevel(logging.DEBUG)
# create console handler and set level to debug
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
fh = logging.FileHandler(outputfile)
fh.setLevel(logging.DEBUG)
# create formatter
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

# add formatter to ch
ch.setFormatter(formatter)
fh.setFormatter(formatter)

# add ch to logger
logger.addHandler(ch)
logger.addHandler(fh)

# GC algorithms
gc_openj9 = [
    {'gc_descr': 'Generational Concurrent policy', 'gc_descr_short': 'GenCon', 'gc_switch': '-Xgcpolicy:gencon'},
#    {'gc_descr': 'Generational Concurrent policy with Concurrent Scavenge', 'gc_descr_short': 'GenConSca', 'gc_switch': '-Xgcpolicy:gencon -Xgc:concurrentScavenge'},
    {'gc_descr': 'Balanced policy', 'gc_descr_short': 'Balanced', 'gc_switch': '-Xgcpolicy:balanced'},
    {'gc_descr': 'Metronome policy', 'gc_descr_short': 'Metronome', 'gc_switch': '-Xgcpolicy:metronome'},
    {'gc_descr': 'Optimize Pause policy', 'gc_descr_short': 'OptAvgPause', 'gc_switch': '-Xgcpolicy:optavgpause'},
    {'gc_descr': 'Optimize Throughput policy', 'gc_descr_short': 'OptTruPut', 'gc_switch': '-Xgcpolicy:optthruput'}
]

gc_openjdk_8 = [
    {'gc_descr': 'G1GC', 'gc_descr_short': 'G1GC', 'gc_switch': '-XX:+UseG1GC'},
#    {'gc_descr': 'G1GC Aggressive heap', 'gc_descr_short': 'G1GC AggHeap', 'gc_switch': '-XX:+UseG1GC -XX:-AggressiveHeap'},
    {'gc_descr': 'Parallel GC', 'gc_descr_short': 'Parallel', 'gc_switch': '-XX:+UseParallelGC'},
#    {'gc_descr': 'Parallel Old GC', 'gc_descr_short': 'ParallelOld', 'gc_switch': '-XX:+UseParallelOldGC'},
    {'gc_descr': 'Serial GC', 'gc_descr_short': 'Serial', 'gc_switch': '-XX:+UseSerialGC'},
    {'gc_descr': 'Concurrent Mark Sweep', 'gc_descr_short': 'CMS', 'gc_switch': '-XX:+UseConcMarkSweepGC'}
]
gc_zing_8 = [
    {'gc_descr': 'Continuously Concurrent Compacting Collector', 'gc_descr_short': 'C4', 'gc_switch': ''}
]

gc_openjdk_11 = gc_openjdk_8 + [
    {'gc_descr': 'Z Garbage Collector', 'gc_descr_short': 'ZGC', 'gc_switch': '-XX:+UnlockExperimentalVMOptions -XX:+UseZGC'}
]

gc_zing_11 = [
    {'gc_descr': 'Continuously Concurrent Compacting Collector', 'gc_descr_short': 'C4', 'gc_switch': ''}
]

gc_openjdk_12 = gc_openjdk_11 + [
    {'gc_descr': 'Shenandoah GC', 'gc_descr_short': 'ShenGC', 'gc_switch': '-XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC'}
]

# Additional options
openj9_opt = '‑Xshareclasses:name=Cache1 -Xdump:none'
zing_opt='-XX:-AutoTuneResourceDefaultsBasedOnXmx'
# Configurations to test
memory_conf = ['-Xmx512m -Xms512m', '-Xmx128m -Xms128m','-Xmx50m -Xms50m']
memory_conf_zing = ['-Xmx512m -Xms512m']

cpuset_conf = ['3', '5,7,9,11','4,5,6,7,8,9,10,11']
concurrency_conf = ['1', '4', '8']

# JAR files to test with
jarfiles = [{'filename': 'akka-rest-service-8.jar', 'description': 'Akka'},
            {'filename': 'quarkus-rest-service-8.jar', 'description': 'Quarkus'},
            {'filename': 'helidon-rest-service-8.jar', 'description': 'Helidon SE'},
            {'filename': 'sb-rest-service-8.jar', 'description': 'Spring Boot'},
            {'filename': 'micronaut-rest-service-8.jar', 'description': 'Micronaut'},
#            {'filename': 'sb-rest-service-fu-8.jar', 'description': 'Spring Fu'},
            {'filename': 'mp-rest-service-8.jar', 'description': 'Open Liberty'},
            {'filename': 'sb-rest-service-reactive-8.jar', 'description': 'Spring Boot WebFlux'},
            {'filename': 'noframework-rest-service-8.jar', 'description': 'No framework'},
            {'filename': 'vertx-rest-service-8.jar', 'description': 'Vert.x'}]

# JVMs to test
jvms = [{'shortname': 'openj9_8_222', 'description': 'OpenJ9 8','vendor':'OpenJ9',
         'location': '/home/maarten/Downloads/jdk8u222-b10/bin/java', 'version_major': '8',
         'version_minor': '222', 'gc': gc_openj9, 'additional': openj9_opt,'mem_conf':memory_conf},
        {'shortname': 'openj9_11_04', 'description': 'OpenJ9 11','vendor':'OpenJ9',
         'location': '/home/maarten/Downloads/jdk-11.0.4+11/bin/java', 'version_major': '11',
         'version_minor': '04', 'gc': gc_openj9, 'additional': openj9_opt,'mem_conf':memory_conf},
        {'shortname': 'openj9_12_02', 'description': 'OpenJ9 12','vendor':'OpenJ9',
         'location': '/home/maarten/Downloads/jdk-12.0.2+10/bin/java', 'version_major': '12',
         'version_minor': '02', 'gc': gc_openj9, 'additional': openj9_opt,'mem_conf':memory_conf},
        {'shortname': 'openj9_13_00', 'description': 'OpenJ9 13','vendor':'OpenJ9',
         'location': '/home/maarten/Downloads/jdk13openj9/bin/java', 'version_major': '13',
         'version_minor': '00', 'gc': gc_openj9, 'additional': openj9_opt,'mem_conf':memory_conf},
        {'shortname': 'openjdk_8_222', 'description': 'OpenJDK 8','vendor':'OpenJDK',
         'location': '/usr/lib/jvm/java-8-openjdk-amd64/bin/java', 'version_major': '8',
         'version_minor': '222', 'gc': gc_openjdk_8, 'additional': '','mem_conf':memory_conf},
        {'shortname': 'openjdk_12_02', 'description': 'OpenJDK 12', 'location': '/usr/lib/jvm/zulu-12-amd64/bin/java',
         'version_major': '12','vendor':'OpenJDK',
         'version_minor': '0.2', 'gc': gc_openjdk_12, 'additional': '','mem_conf':memory_conf},
        {'shortname': 'openjdk_13_33', 'description': 'OpenJDK 13', 'location': '/home/maarten/Downloads/jdk-13+33/bin/java',
         'version_major': '13','vendor':'OpenJDK',
         'version_minor': '33', 'gc': gc_openjdk_12, 'additional': '','mem_conf':memory_conf},
        {'shortname': 'oraclejdk_12_02', 'description': 'OracleJDK 12', 'location': '/usr/lib/jvm/jdk-12.0.2/bin/java',
         'version_major': '12','vendor':'Oracle',
         'version_minor': '0.2', 'gc': gc_openjdk_11, 'additional': '','mem_conf':memory_conf},
        {'shortname': 'oraclejdk_11_03', 'description': 'Oracle JDK 11', 'location': '/usr/lib/jvm/jdk-11.0.3/bin/java',
         'version_major': '11','vendor':'Oracle',
         'version_minor': '0.3', 'gc': gc_openjdk_11, 'additional': '','mem_conf':memory_conf},
        {'shortname': 'oraclejdk_8_221', 'description': 'Oracle JDK 8', 'location': '/home/maarten/Downloads/jdk1.8.0_221/bin/java',
         'version_major': '8','vendor':'Oracle',
         'version_minor': '221', 'gc': gc_openjdk_8, 'additional': '','mem_conf':memory_conf},
        {'shortname': 'oraclejdk_13_33', 'description': 'Oracle JDK 13', 'location': '/usr/lib/jvm/jdk-13/bin/java',
         'version_major': '13','vendor':'Oracle',
         'version_minor': '33', 'gc': gc_openjdk_11, 'additional': '','mem_conf':memory_conf},
        {'shortname': 'openjdk_11_04', 'description': 'OpenJDK 11','vendor':'OpenJDK',
         'location': '/usr/lib/jvm/java-11-openjdk-amd64/bin/java', 'version_major': '11',
         'version_minor': '0.4', 'gc': gc_openjdk_11, 'additional': '','mem_conf':memory_conf},
        {'shortname': 'zing_8_1908', 'description': 'Zing 8','vendor':'Zing',
         'location': '/opt/zing/zing-jdk1.8.0-19.08.0.0-5/bin/java', 'version_major': '8',
         'version_minor': '19.08', 'gc': gc_zing_8, 'additional': zing_opt,'mem_conf':memory_conf_zing},
        {'shortname': 'zing_11_1908', 'description': 'Zing 11','vendor':'Zing',
         'location': '/opt/zing/zing-jdk11.0.0-19.08.0.0-5/bin/java', 'version_major': '11',
         'version_minor': '00', 'gc': gc_zing_11, 'additional': zing_opt,'mem_conf':memory_conf_zing},
        {'shortname': 'graalvm_8_19201', 'description': 'GraalVM 8','vendor':'GraalVM',
         'location': '/home/maarten/Downloads/graalvm-ce-19.2.0.1/bin/java', 'version_major': '8',
         'version_minor': '201', 'gc': gc_openjdk_8, 'additional': '','mem_conf':memory_conf}
        ]

def check_prereqs():
    resval = True;
    for jarfile in jarfiles:
        if not os.path.isfile(jarfile.get('filename')):
            print('File not found: ' + jarfile.get('filename'))
            resval = False
    for jvm in jvms:
        if not os.path.isfile(jvm.get('location')):
            print('File not found: ' + jvm.get('location'))
            resval = False
    return resval

def build_jvmcmd(jvmloc, gc, mem, opt, jar):
    return jvmloc + ' ' + gc + ' ' + mem + ' ' + '-jar ' + jar + ' ' + opt

#Estimate test duration
def estimate_duration():
    total=0
    for jvm in jvms:
        for gc in jvm.get('gc'):
            for mem in jvm.get('mem_conf'):
                for jarfile in jarfiles:
                    for cpuset in cpuset_conf:
                        for concurrency in concurrency_conf:
                            total=total+test_duration+primer_duration+wait_after_primer+wait_to_start
    return total/60/60

#counts from a comma separated list the number of cpus
def get_cpu_num(cpuset):
    return len(cpuset.split(','))

def exec_all_tests():
    logger.info('Estimated duration: '+str(estimate_duration())+' hours')
    logger.info('Using logfile: '+resultsfile)
    with open(resultsfile, 'a') as the_file:
        the_file.write('jvm_short,jvm_descr,jvm_vendor,jvm_major_version,gc_descr,gc_short,framework,memflag,compl_req,failed_req,req_per_sec,time_per_req_avg,cpus,concurrency,duration\n')
    for jvm in jvms:
        for gc in jvm.get('gc'):
            for mem in jvm.get('mem_conf'):
                for jarfile in jarfiles:
                    jvmcmd=build_jvmcmd(jvm.get('location'),gc.get('gc_switch'),mem,jvm.get('additional'),jarfile.get('filename'))
                    jvm_outputline=jvm.get('shortname')+','+jvm.get('description')+','+jvm.get('vendor')+','+jvm.get('version_major')+','+gc.get('gc_descr')+','+gc.get('gc_descr_short')+','+jarfile.get('description')+','+mem
                    logger.info('Processing: ' + jvm_outputline + ' using command: ' + jvmcmd)
                    for cpuset in cpuset_conf:
                        cpunum=str(get_cpu_num(cpuset))
                        logger.info('Number of CPUs ' + cpunum)
                        for concurrency in concurrency_conf:
                            logger.info('Number of concurrent requests ' + concurrency)
                            pid=start_java_process(jvmcmd,concurrency)
                            logger.info('Java process PID is: ' + pid)
                            if (len(str(pid))==0):
                                pid=start_java_process(jvmcmd,concurrency)
                                logger.warning('Retry startup. Java process PID is: ' + pid)
                                if (len(str(pid))==0):
                                    pid=start_java_process(jvmcmd,concurrency)
                                    logger.warning('Second retry startup. Java process PID is: ' + pid)
                            if (len(str(pid))==0 and len(str(get_java_process_pid()))>0):
                                pid=get_java_process_pid()
                                logger.info('Setting new PID to '+pid)
                            try:
                                output_primer=execute_test_single(concurrency, primer_duration)
                                time.sleep(wait_after_primer)
                                output_test=execute_test_single(concurrency, test_duration)
                                ab_output=parse_ab_output(output_test)
                                outputline=jvm_outputline+','+ab_output.get('compl_req')+','+ab_output.get('failed_req')+','+ab_output.get('req_per_sec')+','+ab_output.get('time_per_req_avg')+','+cpunum+','+concurrency
                            except:
                                #Retry
                                logger.warning('Executing retry')
                                time.sleep(wait_to_start)
                                try:
                                     output_primer=execute_test_single(concurrency, primer_duration)
                                     time.sleep(wait_after_primer)
                                     output_test=execute_test_single(concurrency, test_duration)
                                     ab_output=parse_ab_output(output_test)
                                     outputline=jvm_outputline+','+ab_output.get('compl_req')+','+ab_output.get('failed_req')+','+ab_output.get('req_per_sec')+','+ab_output.get('time_per_req_avg')+','+cpunum+','+concurrency
                                except:
                                     logger.warning("Giving up. Test failed. Writing FAILED to results file")
                                     outputline = jvm_outputline + ',FAILED,FAILED,FAILED,FAILED,' + cpunum + ',' + concurrency
                            outputline=outputline+','+str(test_duration)
                            with open(resultsfile, 'a') as the_file:
                                the_file.write(outputline+'\n')
                            kill_process(pid)
                            clean_tmpfiles()
    return

def clean_tmpfiles():
    try: 
        cmd='rm -rf ~/wlpExtract'
        subprocess.getoutput(cmd)
        cmd='rm -f jitdump.*'
        subprocess.getoutput(cmd)
        cmd='rm -f javacore.*'
        subprocess.getoutput(cmd)
        cmd='rm -f Snap.*'
        subprocess.getoutput(cmd)
    except:
        None
    return

def parse_ab_output(ab_output):
    retval={}
    for line in ab_output.splitlines():
        x = re.search("^Complete requests\:\s+(\d+)$", line)
        if x is not None:
            retval['compl_req'] = x.group(1)
        x = re.search("^Failed requests\:\s+(\d+)$", line)
        if x is not None:
            retval['failed_req']=x.group(1)
        x = re.search("^Requests per second\:\s+(\d+\.\d+) .*$", line)
        if x is not None:
            retval['req_per_sec']=x.group(1)

        x = re.search("^Time per request\:\s+(\d+\.\d+) \[ms\] \(mean, across all concurrent requests\)$", line)
        if x is not None:
            retval['time_per_req_avg'] = x.group(1)
    return retval

def get_java_process_pid():
    cmd='ps -o pid,sess,cmd afx | egrep "( |/)java.*service.*-8.jar.*( -f)?$" | awk \'{print $1}\''
    output = subprocess.getoutput(cmd)
    return output

def start_java_process(java_cmd,cpuset):
    oldpid=get_java_process_pid()
    if (oldpid.isdecimal()):
        logger.info('Old Java process found with PID: ' + oldpid+'. Killing it')
        kill_process(oldpid)
    clean_tmpfiles()
    cmd='taskset -c '+cpuset+' '+java_cmd
    subprocess.Popen(cmd.split(' '), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    time.sleep(wait_to_start)
    return get_java_process_pid()

def execute_test_single(concurrency,duration):
    logger.info('Executing test with concurrency: '+str(concurrency)+' and duration '+str(duration))
    cmd = 'ab -l -q -t ' + str(duration) + ' -n 100000000000000 -c ' + str(concurrency) + ' http://localhost:8080/greeting?name=Maarten'
    process = subprocess.run(cmd.split(), check=True, stdout=subprocess.PIPE, universal_newlines=True)
    output = process.stdout
    logger.info('Executing test done')
    return output

def kill_process(pid):
    logger.info('Killing process with PID: '+pid)
    try:
        os.kill(int(pid), signal.SIGKILL)
    except:
        logger.info('Process not found')
    try:
        #this will fail if the process is not a childprocess
        os.waitpid(int(pid), 0)
    except:
        #Just to be sure the process is really gone
        time.sleep(wait_after_kill)
    return

def main():
    if (not check_prereqs()):
        logger.error('Prerequisites not satisfied. Exiting')
        exit(1)
    else:
        logger.info('Prerequisites satisfied')
    print(exec_all_tests())
    logger.info('Test execution finished')

if __name__ == '__main__':
    main()
