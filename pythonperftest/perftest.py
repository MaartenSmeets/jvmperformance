import sys
import os
import requests
import signal
import time

URL = "http://localhost:8080/greeting"
LOGFILEDIR = '.'

forks = 4
if len(sys.argv) == 2:
    URL = int(sys.argv[1])
if len(sys.argv) == 3:
    LOGFILEDIR = int(sys.argv[3])

lines_of_text = []


def log(line):
    lines_of_text.append(line+"\n")

def signal_handler(sig, frame):
    print("INFO\t{}\tSIGNAL RECEIVED".format(os.getpid())+" "+str(signal.Signals(sig)))
    fh.writelines(lines_of_text)
    fh.close()
    sys.exit(0)


log("INFO\t{}\tProcess id before forking".format(os.getpid()))
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

for i in range(forks):
    try:
        pid = os.fork()
    except OSError:
        log("ERROR\t{}\tCould not create a child process".format(os.getpid()))
        continue

    if pid == 0:
        mypid=os.getpid()
        log("INFO\t{}\tStarted worker".format(mypid))
        fh = open(LOGFILEDIR + '/' + str(mypid) + '.log', "w")
        while True:
            try:
                start = time.clock()
                response = requests.get(
                    URL,
                    params={'name': 'Maarten'},
                )
                request_time = time.clock() - start
                log("MEASURE\t{}\t{0:.0f}".format(mypid,request_time))
            except Exception as e:
                log("ERROR\t{}\t{}".format(mypid, str(e)))

try:
    fh
except NameError:
    fh = open(LOGFILEDIR + '/' + str(os.getpid()) + '.log', "w")

log("INFO\t{}\tIn the parent process after forking".format(os.getpid()))

for i in range(forks):
    finished = os.waitpid(0, 0)
    print(finished)
