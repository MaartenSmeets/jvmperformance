import os
import signal
import sys
import time
import requests

forks = 1
URL = os.getenv('URL', "http://localhost:8080/greeting")
LOGFILEDIR = os.getenv('LOGFILEDIR', "/logs")

try:
    if not os.path.exists(LOGFILEDIR):
        os.mkdir(LOGFILEDIR)
except Exception as e:
    LOGFILEDIR = os.getcwd()

lines_of_text = []
pid = 0
child_pids = []


def log(line):
    lines_of_text.append(line + "\n")


def exit_signal_handler(sig, frame):
    log("INFO\t{}\tSIGNAL RECEIVED {}".format(os.getpid(), str(signal.Signals(sig))))
    if pid > 0:
        for child_pid in child_pids:
            log("INFO\t{}\tKILLING PID {}".format(os.getpid(), child_pid))
            try:
                os.kill(child_pid, signal.SIGINT)
                finished = os.waitpid(child_pid, 0)
            except Exception as e:
                log("CLEANUP_ERROR\t{}\tKILLING PID {} failed: {}".format(os.getpid(), child_pid, str(e)))
    fh.writelines(lines_of_text)
    fh.close()
    sys.exit(0)


log("INFO\t{}\tProcess id before forking".format(os.getpid()))
signal.signal(signal.SIGINT, exit_signal_handler)
signal.signal(signal.SIGTERM, exit_signal_handler)

for i in range(forks):
    try:
        pid = os.fork()
        if pid > 0:
            child_pids.append(pid)
    except OSError:
        log("FORK_ERROR\t{}\tCould not create a child process".format(os.getpid()))
        continue

    if pid == 0:
        mypid = os.getpid()
        log("INFO\t{}\tStarted worker".format(mypid))
        fh = open(LOGFILEDIR + '/' + str(mypid) + '.log', "w")
        while True:
            try:
                start = time.time()
                response = requests.get(
                    URL,
                    params={'name': 'Maarten'},
                    headers={"Connection": "close"},
                    timeout=30
                )
                stop = time.time()
                request_time = (stop - start)*1000
                log("MEASURE\t{}\t{}".format(mypid, request_time))
            except Exception as e:
                log("REQUEST_ERROR\t{}\t{}".format(mypid, str(e)))

try:
    fh
except NameError:
    fh = open(LOGFILEDIR + '/' + str(os.getpid()) + '.log', "w")

log("INFO\t{}\tIn the parent process after forking".format(os.getpid()))

for i in range(forks):
    finished = os.waitpid(0, 0)
    print(finished)
