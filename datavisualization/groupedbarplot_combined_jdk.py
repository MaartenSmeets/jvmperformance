from matplotlib import pyplot as plt
from matplotlib.pyplot import figure
import pandas as pd
import numpy as np
import os
import itertools as it

plt.close('all')

# set width of bar
barWidth = 0.75

#point the below line to the test output directory
processdir8='/home/maarten/t/jvmperformance/testscripts/jdktest_8_20190508175957'
processdir11='/home/maarten/t/jvmperformance/testscripts/jdktest_11_20190508214950'

averagecmd8='cat '+processdir8+'/outputfile.txt | grep AVERAGE_PROC | awk \'{print $1","$3}\' > '+processdir8+'/average.txt'
stddevcmd8='cat '+processdir8+'/outputfile.txt | grep STANDARD_DEVIATION_MS | awk \'{print $1","$3}\' > '+processdir8+'/stddev.txt'
print ('Executing: '+averagecmd8)
os.system(averagecmd8)

print ('Executing: '+stddevcmd8)
os.system(stddevcmd8)

averagecmd11='cat '+processdir11+'/outputfile.txt | grep AVERAGE_PROC | awk \'{print $1","$3}\' > '+processdir11+'/average.txt'
stddevcmd11='cat '+processdir11+'/outputfile.txt | grep STANDARD_DEVIATION_MS | awk \'{print $1","$3}\' > '+processdir11+'/stddev.txt'
print ('Executing: '+averagecmd11)
os.system(averagecmd11)

print ('Executing: '+stddevcmd11)
os.system(stddevcmd11)

df1 = pd.read_csv(processdir8+'/average.txt', sep=',', header=None)
df2 = pd.read_csv(processdir8+'/stddev.txt', sep=',', header=None)
df3 = pd.read_csv(processdir11+'/average.txt', sep=',', header=None)
df4 = pd.read_csv(processdir11+'/stddev.txt', sep=',', header=None)

df1.columns = ['jvm_framework_ident','average']
df2.columns = ['jvm_framework_ident','stddev']
df3.columns = ['jvm_framework_ident','average']
df4.columns = ['jvm_framework_ident','stddev']

df5 = pd.merge(df1,df2,on="jvm_framework_ident")
df5['version']=8
df6 = pd.merge(df3,df4,on="jvm_framework_ident")
df6['version']=11

df_new = pd.concat([df5, df6])

df_new[['jvm','framework']] = df_new['jvm_framework_ident'].str.split('_',expand=True)

df_average_per_jvm=df_new.groupby(['jvm','version']).mean().reset_index()

jvm_dict={'graalvm':'GraalVM','openj9':'OpenJ9','adoptopenjdk':'AdoptOpenJDK','oraclejdk':'Oracle JDK','zuluopenjdk':'Azul Zulu'}

df_average_per_jvm.sort_values(['jvm','version'], ascending=[True,True])

df_average_per_jvm['jvm_descr'] = df_average_per_jvm['jvm'].map(jvm_dict)

df_average_per_jvm["jvm_total"] = df_average_per_jvm["jvm_descr"].map(str)+" "+df_average_per_jvm["version"].map(str)

jvms=df_average_per_jvm['jvm_total'].unique()

#based on https://python-graph-gallery.com/11-grouped-barplot/
#calculate bar location. rowloc[0] is the location for the first bar in every group (group=jvm). 2 bars, 8 and 11
rowloc=[]
rowloc.append(np.arange(len(jvms)))

my_colors = list(it.islice(it.cycle(['#FF5733', '#33CEFF']), None, len(df_average_per_jvm)))

# Make the plot
figure(num=None, figsize=(8, 6))
plt.bar(rowloc[0], df_average_per_jvm['average'], yerr=df_average_per_jvm['stddev'],edgecolor='white', label=df_average_per_jvm['jvm_total'],color=my_colors,width=barWidth,capsize=2)

#plt.xticks([r + (barWidth*(len(jvms)/2)) for r in range(len(frameworks))], frameworks)
plt.xticks(rowloc[int(len(rowloc)/2)], jvms)

plt.ylabel('Average response time [ms]')
plt.xlabel('JVM')
plt.title('Average response time per JVM')
plt.tight_layout()
plt.savefig('java_barplot_perjdk.png', dpi=100)
