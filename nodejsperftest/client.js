var request = require('request');
var async = require('async');
var cluster = require('cluster');
var process = require('process');
var pid = process.pid;
var forks = 4;
var killedcounter=0;
var fs = require('fs');

//Example call: node client.js http://9292ov.nl .

var URL = process.env.URL || 'http://localhost:8080/greeting?name=Maarten';
var LOGFILEDIR = process.env.LOGFILEDIR || '/logs';
var LOGFILE;

if (LOGFILEDIR) {
    LOGFILE = String(LOGFILEDIR) + '/' + pid + ".log"
}

var fileStream;

if (LOGFILE) {
    fileStream = fs.createWriteStream(LOGFILE, {
        flags: 'a'
    });
}

var lineBuffer = '';

function mylogger(msg) {
        lineBuffer = lineBuffer + msg + "\n";
};

function cleanup() {
    if (LOGFILE) {
        mylogger("INFO\t"+pid+"\tCleanup called");
        if (cluster.isMaster) {
            for (const id in cluster.workers) {
                mylogger("INFO\t"+pid+"\tSending SIGINT to worker with id: "+String(id));
                cluster.workers[id].process.kill();
            }
        }
        fileStream.write(lineBuffer);
        fileStream.end();
    }
    return;
}

process.on('SIGTERM', (error, next) => {
    mylogger("INFO\t"+pid+"\tSIGTERM received");
    cleanup();
});

process.on('SIGINT', (error, next) => {
    mylogger("INFO\t"+pid+"\tSIGINT received");
    cleanup();
});

if (cluster.isMaster) {
    mylogger("MASTER\t" + pid);    
    mylogger("URL\t" + pid+"\t"+String(URL));
    mylogger("LOGFILE\t" +pid+"\t"+String(LOGFILE));
    for (var i = 0; i < forks; i++) {
        mylogger("INFO\t" + pid + "\tMaster: creating fork: " + i);
        cluster.fork();
    };
    cluster.on('exit', (worker, code, signal) => {
        killedcounter=killedcounter+1;
        if (killedcounter==forks) {
            process.exit();
        }
    });
} else {
    mylogger("WORKER\t" + pid);        
    mylogger("URL\t" + pid+"\t"+String(URL));
    mylogger("LOGFILE\t" + pid+"\t"+String(LOGFILE));
    async.forever(
        function(next) {
            request.get({
                url: URL,
                time: true
            }, function(error, response, body) {
                if (!error && response.statusCode == 200) {
                    mylogger("MEASURE\t" + pid+"\t"+String(response.elapsedTime));
                    next();
                } else {
                    if (error && response) {
                        mylogger("INFO\t" + pid + "\tError! " + String(error) + " Response code: " + String(response.statusCode));
                        next();
                    } else {
                        mylogger("INFO\t" + pid + "\tError! " + String(error));
                        next();
                    }
                }
            });
        },
        function(err) {
            mylogger("INFO\t" + pid + " Error!\t" + String(err));
        }
    );
}
