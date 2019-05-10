from matplotlib import pyplot as plt
from matplotlib.pyplot import figure
import pandas as pd
import numpy as np
import os

plt.close('all')

# set width of bar
barWidth = 0.15

#point the below line to the test output directory
processdir='/home/maarten/t/jvmperformance/testscripts/test_8_11_15m_2gb/jdktest_8_20190509214852'

averagecmd='cat '+processdir+'/outputfile.txt | grep AVERAGE_PROC | awk \'{print $1","$3}\' > '+processdir+'/average.txt'
stddevcmd='cat '+processdir+'/outputfile.txt | grep STANDARD_DEVIATION_MS | awk \'{print $1","$3}\' > '+processdir+'/stddev.txt'
print ('Executing: '+averagecmd)
os.system(averagecmd)

print ('Executing: '+stddevcmd)
os.system(stddevcmd)

df1 = pd.read_csv(processdir+'/average.txt', sep=',', header=None)
df2 = pd.read_csv(processdir+'/stddev.txt', sep=',', header=None)
df1.columns = ['jvm_framework_ident','average']
df2.columns = ['jvm_framework_ident','stddev']


df1 = pd.merge(df1,df2,on="jvm_framework_ident")

df1[['jvm','framework']] = df1['jvm_framework_ident'].str.split('_',expand=True)
df2[['jvm','framework']] = df2['jvm_framework_ident'].str.split('_',expand=True)

#check data
jvms=df1.jvm.unique()
jvms.sort()
jvms2=df2.jvm.unique()
jvms2.sort()
frameworks=df1.framework.unique()
frameworks.sort()
if len(list(set(jvms) & set(jvms2)))!=len(jvms):
    print ('Averages and Standard Errors do not contain data for the same JVMs'+str(list(set(jvms) & set(jvms2))))
    exit(1)

framework_dict={'mp':'MicroProfile','sb':'Spring Boot','sbreactive':'Spring Boot Reactive','sbfu':'Spring Fu','vertx':'VertX'}
jvm_dict={'graalvm':'GraalVM','openj9':'OpenJ9','adoptopenjdk':'AdoptOpenJDK','oraclejdk':'Oracle JDK','zuluopenjdk':'Azul Zulu'}

#Add descriptions and sort
df1['jvm_descr'] = df1['jvm'].map(jvm_dict)
df1['framework_descr'] = df1['framework'].map(framework_dict)
df1.sort_values(['jvm', 'framework'], ascending=[True, True])

#check data
for jvm in jvms:
    averages=df1.loc[df1['jvm'] == jvm, 'average']
    if (len(averages) < len(frameworks)):
        print ('Dataset for '+jvm+' incomplete! Found '+str(len(averages))+' averaged but expected '+str(len(frameworks)))
        exit(1)

#based on https://python-graph-gallery.com/11-grouped-barplot/
#calculate bar location. rowloc[0] is the location for the first bar in every group (group=keys from framework_dict)
rowloc=[]
rowloc.append(np.arange(len(frameworks)))
for item in range(1,(len(jvms))):
    rowloc.append([x + barWidth for x in rowloc[item-1]])

averages=[]
#Add for each JVM averages (every average is for a specific framework)
for jvm in jvms:
    averages.append(df1.loc[df1['jvm']==jvm,'average'])

stddevs=[]
#Add for each JVM averages (every average is for a specific framework)
for jvm in jvms:
    stddevs.append(df1.loc[df1['jvm']==jvm,'stddev'])

# Make the plot
figure(num=None, figsize=(8, 6))
for item in range(0,len(jvms)):
    plt.bar(rowloc[item], averages[item],yerr=stddevs[item], width=barWidth, edgecolor='white', label=jvm_dict[jvms[item]],capsize=2)

plt.xticks(rowloc[int(len(rowloc)/2)], [framework_dict[x] for x in frameworks])
plt.ylim(0, 8)

plt.legend([jvm_dict[x] for x in jvms])

plt.ylabel('Average response time [ms]')
plt.xlabel('Framework')
plt.title('Microservice framework average response time per JVM 8u202')
plt.tight_layout()
plt.savefig('java8barplot.png', dpi=100)
