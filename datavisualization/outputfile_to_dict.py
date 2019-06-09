import subprocess
output_dict={}

#must be run in a folder where outputfile.txt exists. typically this is the output of the ../testscripts/runtest.sh script
#the keys of the dict will be the subdirectories of that directory

filepath = 'outputfile.txt' 
list_of_measures = [ 'CPUTIME_MS', 'REQUESTS_PROCESSED', 'AVERAGE_PROCESSING_TIME_MS', 'STANDARD_DEVIATION_MS', 'PROM_REQUESTS', 'PROM_AVERAGE_MS' ,'PROM_TOTALTIME_S', 'JAVA_VERSION', 'BASE_IMAGE', 'GC_ALGORITHM' ]

dirs_buffer=subprocess.Popen("ls -1 -d */", shell=True, stdout=subprocess.PIPE).stdout.read()

#Decode it so the buffer becomes a string
dirs=dirs_buffer.decode("utf-8") 

#Split on newline to make it a list
dirs_list=dirs.split("\n")

#remove empty strings
dirs_list=list(filter(None, dirs_list))

#remove trailing /
dirs_list = [x[:-1] for x in dirs_list] 

def join(l, sep):
    li = iter(l)
    string = str(next(li))
    for i in li:
        string += str(sep) + str(i)
    return string

with open(filepath) as fp:  
   line = fp.readline()
   while line:
       line = fp.readline()
       for dir in dirs_list:
            if line.startswith(dir+' '):
                line=line.rstrip()
                line_items=line.split(' ')
                if line_items[1].rstrip(':') in list_of_measures:
                    #print(line_items[0]+"\t"+line_items[1].rstrip(':')+"\t"+join(line_items[2:],' '))
                    if not line_items[0] in output_dict:
                        output_dict[line_items[0]] = {}
                    output_dict[line_items[0]][line_items[1].rstrip(':')]=join(line_items[2:],' ')

print (output_dict)
