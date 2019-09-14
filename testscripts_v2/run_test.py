import os.path

# GC algorithms
gc_openj9 = [
    {'gc_descr': 'Generational Concurrent policy', 'gc_descr_short': 'GenCon', 'gc_switch': '-Xgcpolicy:gencon'},
    {'gc_descr': 'Generational Concurrent policy with Concurrent Scavenge', 'gc_descr_short': 'GenConSca',
     'gc_switch': '-Xgcpolicy:gencon -Xgc:concurrentScavenge'},
    {'gc_descr': 'Balanced policy', 'gc_descr_short': 'Balanced', 'gc_switch': '-Xgcpolicy:balanced'},
    {'gc_descr': 'Metronome policy', 'gc_descr_short': 'Metronome', 'gc_switch': '-Xgcpolicy:metronome'},
    {'gc_descr': 'Optimize Pause policy', 'gc_descr_short': 'OptAvgPause', 'gc_switch': '-Xgcpolicy:optavgpause'},
    {'gc_descr': 'Optimize Throughput policy', 'gc_descr_short': 'OptTruPut', 'gc_switch': '-Xgcpolicy:optthruput'}
]

gc_openjdk_8 = [
    {'gc_descr': 'G1GC', 'gc_descr_short': 'G1GC', 'gc_switch': '-XX:+UseG1GC'},
    {'gc_descr': 'G1GC Aggressive heap', 'gc_descr_short': 'G1GC AggHeap',
     'gc_switch': '-XX:+UseG1GC -XX:-AggressiveHeap'},
    {'gc_descr': 'Parallel GC', 'gc_descr_short': 'Parallel', 'gc_switch': '-XX:+UseParallelGC'},
    {'gc_descr': 'Parallel Old GC', 'gc_descr_short': 'ParallelOld', 'gc_switch': '-XX:+UseParallelOldGC'},
    {'gc_descr': 'Serial GC', 'gc_descr_short': 'Serial', 'gc_switch': '-XX:+UseSerialGC'},
    {'gc_descr': 'Concurrent Mark Sweep', 'gc_descr_short': 'CMS', 'gc_switch': '-XX:+UseConcMarkSweepGC'}
]
gc_zing_8 = gc_openjdk_8 + [
    {'gc_descr': 'Continuously Concurrent Compacting Collector', 'gc_descr_short': 'C4', 'gc_switch': ''}
]

gc_openjdk_11 = gc_openjdk_8 + [
    {'gc_descr': 'Z Garbage Collector', 'gc_descr_short': 'ZGC', 'gc_switch': '-XX:+UseZGC'}
]

gc_zing_11 = gc_openjdk_11 + [
    {'gc_descr': 'Continuously Concurrent Compacting Collector', 'gc_descr_short': 'C4', 'gc_switch': ''}
]

gc_openjdk_12 = gc_openjdk_11 + [
    {'gc_descr': 'Shenandoah GC', 'gc_descr_short': 'ShenGC',
     'gc_switch': '-XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC'}
]

# Additional options
openj9_opt = '‑Xshareclasses:name=Cache1'

#Configurations to test
memory_conf = ['-Xmx1G -Xms1G', '-Xmx256m -Xms256m', '-Xmx50m -Xms50m']
cpuset_conf = ['4', '4,6', '4,6,8,12']
concurrency_conf = ['1', '2', '4']

#JAR files to test with
jarfiles = [{'filename': 'akka-rest-service-8.jar', 'description': 'Akka'},
            {'filename': 'quarkus-rest-service-8.jar', 'description': 'Quarkus'},
            {'filename': 'helidon-rest-service-8.jar', 'description': 'Helidon SE'},
            {'filename': 'sb-rest-service-8.jar', 'description': 'Spring Boot'},
            {'filename': 'micronaut-rest-service-8.jar', 'description': 'Micronaut'},
            {'filename': 'sb-rest-service-fu-8.jar', 'description': 'Spring Fu'},
            {'filename': 'mp-rest-service-8.jar', 'description': 'Open Liberty'},
            {'filename': 'sb-rest-service-reactive-8.jar', 'description': 'Spring Boot WebFlux'},
            {'filename': 'noframework-rest-service-8.jar', 'description': 'No framework'},
            {'filename': 'vertx-rest-service-8.jar', 'description': 'Vert.x'}]

#JVMs to test
jvms = [{'shortname':'openj9_8_222','description':'OpenJ9 8','location': '/home/maarten/Downloads/jdk8u222-b10/bin/java', 'version_major': 8,
                         'version_minor': '222', 'gc': gc_openj9, 'additional': openj9_opt},
        {'shortname':'openj9_11_04','description':'OpenJ9 11','location': '/home/maarten/Downloads/jdk-11.0.4+11/bin/java', 'version_major': 11,
                         'version_minor': '04', 'gc': gc_openj9, 'additional': openj9_opt},
        {'shortname':'openj9_12_02','description':'OpenJ9 12','location': '/home/maarten/Downloads/jdk-12.0.2+10/bin/java', 'version_major': 12,
                         'version_minor': '02', 'gc': gc_openj9, 'additional': openj9_opt},
        {'shortname':'openjdk_8_222','description':'OpenJDK 8','location': '/usr/lib/jvm/java-8-openjdk-amd64/bin/java', 'version_major': 8,
                          'version_minor': '222', 'gc': gc_openjdk_8, 'additional': ''},
        {'shortname':'openjdk_12_02','description':'OpenJDK 12','location': '/usr/lib/jvm/zulu-12-amd64/bin/java', 'version_major': 12,
                          'version_minor': '0.2', 'gc': gc_openjdk_12, 'additional': ''},
        {'shortname':'oraclejdk_12_02','description':'OracleJDK 12','location': '/usr/lib/jvm/jdk-12.0.2/bin/java', 'version_major': 12,
                            'version_minor': '0.2', 'gc': gc_openjdk_12, 'additional': ''},
        {'shortname':'oraclejdk_11_03','description':'Oracle JDK 11','location': '/usr/lib/jvm/jdk-11.0.3/bin/java', 'version_major': 11,
                            'version_minor': '0.3', 'gc': gc_openjdk_11, 'additional': ''},
        {'shortname':'openjdk_11_04','description':'OpenJDK 11','location': '/usr/lib/jvm/java-11-openjdk-amd64/bin/java', 'version_major': 11,
                          'version_minor': '0.4', 'gc': gc_openjdk_11, 'additional': ''},
        {'shortname':'zing_8_1908','description':'Zing 8','location': '/opt/zing/zing-jdk1.8.0-19.08.0.0-5/bin/java', 'version_major': 8,
                        'version_minor': '19.08', 'gc': gc_zing_8, 'additional': ''},
        {'shortname':'zing_11_1908','description':'Zing 11','location': '/opt/zing/zing-jdk11.0.0-19.08.0.0-5/bin/java', 'version_major': 11,
                         'version_minor': '00', 'gc': gc_zing_11, 'additional': ''}
        ]

def check_prereqs():
   resval=True;
   for jarfile in jarfiles:
       if not os.path.isfile(jarfile.get('filename')):
           print ('File not found: '+jarfile.get('filename'))
           resval=False
   for jvm in jvms:
        if not os.path.isfile(jvm.get('location')):
           print ('File not found: '+jvm.get('location'))
           resval=False
   return resval

check_prereqs()