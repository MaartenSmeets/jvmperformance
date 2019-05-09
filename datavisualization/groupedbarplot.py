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
processdir8='/home/maarten/t/jvmperformance/testscripts/jdktest_8_20190509150008'

averagecmd8='cat '+processdir8+'/outputfile.txt | grep AVERAGE_PROC | awk \'{print $1","$3}\' > '+processdir8+'/average.txt'
stddevcmd8='cat '+processdir8+'/outputfile.txt | grep STANDARD_DEVIATION_MS | awk \'{print $1","$3}\' > '+processdir8+'/stddev.txt'
print ('Executing: '+averagecmd8)
os.system(averagecmd8)

print ('Executing: '+stddevcmd8)
os.system(stddevcmd8)

df1 = pd.read_csv(processdir8+'/average.txt', sep=',', header=None)
df2 = pd.read_csv(processdir8+'/stddev.txt', sep=',', header=None)

df1.columns = ['jvm_framework_ident','average']
df2.columns = ['jvm_framework_ident','stddev']
df3.columns = ['jvm_framework_ident','average']
df4.columns = ['jvm_framework_ident','stddev']

df5 = pd.merge(df1,df2,on="jvm_framework_ident")
df5['version']=8

df_new = df5

df_new[['jvm','framework']] = df_new['jvm_framework_ident'].str.split('_',expand=True)

jvms=df_new['jvm'].unique()

#based on https://python-graph-gallery.com/11-grouped-barplot/
#calculate bar location. rowloc[0] is the location for the first bar in every group (group=jvm). 2 bars, 8 and 11
rowloc=[]
rowloc.append(np.arange(len(jvms)))

# Make the plot
figure(num=None, figsize=(16, 6))
plt.bar(rowloc[0], df_new['average'], yerr=df_new['stddev'],edgecolor='white', label=df_average_per_jvm['jvm'],width=barWidth,capsize=2)

#plt.xticks([r + (barWidth*(len(jvms)/2)) for r in range(len(frameworks))], frameworks)
plt.xticks(rowloc[int(len(rowloc)/2)], jvms)

plt.ylabel('Average response time [ms]')
plt.xlabel('JVM')
plt.title('Average response time per JVM')
plt.tight_layout()
plt.savefig('java_barplot_perjdk.png', dpi=100)
