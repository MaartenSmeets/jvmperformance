var request = require('request');
var async = require('async');
var cluster = require('cluster');
var process = require('process');
var pid = process.pid;
var numCPUs = require('os').cpus().length / 2;
var fs = require('fs');

//Example call: node client.js http://9292ov.nl .

var URL = process.argv[2] || "http://localhost:8080/greeting?name=Maarten";
var LOGFILEDIR = process.argv[3];
var LOGFILE

if (LOGFILEDIR) {
    LOGFILE = String(LOGFILEDIR) + '/' + pid + ".log"
}

var fileStream;
var lineBuffer = '';
var lineBufferCounter = 0;
var lineBufferSize = 100;

function cleanup() {
    if (LOGFILE) {
        lineBuffer = lineBuffer + "INFO\t"+pid+"\tCleanup called" + "\n";
        fileStream.write(lineBuffer);
        fileStream.end();
    } else {
        console.log("INFO\t"+pid+"\tCleanup called");
    }    
    cleanup = function() {};
    return;
}

process.on('SIGTERM', (error, next) => {
    cleanup();
    console.log("INFO\t"+pid+"\tSIGTERM received");
    process.exit();
});

process.on('SIGINT', (error, next) => {
    cleanup();
    console.log("INFO\t"+pid+"\tSIGINT received");
    process.exit();
});


if (LOGFILE) {
    fileStream = fs.createWriteStream(LOGFILE, {
        flags: 'a'
    });
}

function mylogger(msg) {
    if (LOGFILE) {
        if (lineBufferCounter < lineBufferSize) {
            lineBuffer = lineBuffer + msg + "\n";
            lineBufferCounter = lineBufferCounter + 1;
        } else {
            fileStream.write(lineBuffer);
            lineBuffer = '';
            lineBufferCounter = 0;
        }
    } else {
        console.log(msg);
    }
};

if (cluster.isMaster) {
    mylogger("MASTER\t" + pid);    
    mylogger("URL\t" + pid+"\t"+String(URL));
    mylogger("LOGFILE\t" +pid+"\t"+String(LOGFILE));
    for (var i = 0; i < numCPUs; i++) {
        mylogger("INFO\t" + pid + "\tMaster: creating fork: " + i);
        worker = cluster.fork();
    };

    cluster.on('exit', (worker, code, signal) => {
        mylogger("INFO\t" + pid + "\tWorker dies");
    });

    cluster.on('online', (worker, code, signal) => {
        mylogger("INFO\t" + pid + "\tWorker started");
    });
} else {
    mylogger("WORKER\t" + pid);        
    mylogger("URL\t" + pid+"\t"+String(URL));
    mylogger("LOGFILE\t" + pid+"\t"+String(LOGFILE));
    async.forever(
        function(next) {
            var startTimeHR = process.hrtime();
            request.get({
                url: URL
            }, function(error, response, body) {
                if (!error && response.statusCode == 200) {
                    var durationHR = process.hrtime(startTimeHR);
                    //mylogger(pid+"\tRequest end. Duration in ms:\t%d", (durationHR[0]*1000)+(durationHR[1] / 1000000));
                    mylogger("MEASURE\t" + pid+"\t"+String((durationHR[0] * 1000) + (durationHR[1] / 1000000)));
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
