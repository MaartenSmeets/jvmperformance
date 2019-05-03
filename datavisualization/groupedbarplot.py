from matplotlib import pyplot as plt
import pandas as pd
import numpy as np
import os

plt.close('all')

# set width of bar
barWidth = 0.15

#point the below line to the test output directory
processdir='/home/maarten/t/jvmperformance/testscripts/jdktest20190503132435'

averagecmd='cat '+processdir+'/outputfile.txt | grep AVERAGE_PROC | awk \'{print $1","$3}\' > '+processdir+'/average.txt'
print ('Executing: '+averagecmd)
os.system(averagecmd)

df1 = pd.read_csv(processdir+'/average.txt', sep=',', header=None)
df1.columns = ['jvm_framework_ident','average']

df1[['jvm','framework']] = df1['jvm_framework_ident'].str.split('_',expand=True)

frameworks=['MicroProfile','Spring Boot','Spring Boot Reactive','Spring Fu','Spring Fu alt']
jvms=['graalvm', 'openj9', 'adoptopenjdk', 'oraclejdk', 'zuluopenjdk']

#check data
for jvm in jvms:
    averages=df1.loc[df1['jvm'] == jvm, 'average']
    if (len(averages) < len(frameworks)):
        print ('Dataset for '+jvm+' incomplete! Found '+str(len(averages))+' averaged but expected '+str(len(frameworks)))
        exit(1)

#based on https://python-graph-gallery.com/11-grouped-barplot/
#calculate bar location. rowloc[0] is the location for the first bar in every group (group=framework)
rowloc=[]
rowloc.append(np.arange(5))
for item in range(1,(len(frameworks)-1)):
    rowloc.append([x + barWidth for x in rowloc[item-1]])

data=[]
#Add for each JVM averages (every average is for a specific framework)
for jvm in jvms:
    data.append(df1.loc[df1['jvm']==jvm,'average'])

# Make the plot
for item in range(0,len(rowloc)):
    plt.bar(rowloc[item], data[item], width=barWidth, edgecolor='white', label=jvms[item])

plt.xticks([r + barWidth for r in range(len(frameworks))], frameworks)

plt.legend(jvms)

plt.ylabel('Average response time [ms]')
plt.xlabel('Framework')
plt.title('Microservice framework average response time per JVM')
