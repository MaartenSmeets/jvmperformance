var request = require('request');
var async = require('async');
var cluster = require('cluster');
var process = require('process');
var pid = process.pid;
var numCPUs = require('os').cpus().length/2;

function mylogger(msg) {
	console.log.apply(null, arguments);
};

if (cluster.isMaster) {
	for (var i = 0; i < numCPUs; i++) {
		mylogger("INFO: "+pid+"\tMaster: creating fork: "+i);
		worker = cluster.fork();
	};
	
	cluster.on('exit',(worker,code,signal) => {
		mylogger("INFO: "+pid+"\tWorker dies");
	});
	
	cluster.on('online',(worker,code,signal) => {
		mylogger("INFO: "+pid+"\tWorker started");
	});
} else {
	mylogger(pid+"\tGenerating request function");
	var requestfunc = function doRequest(callback) {
		var startTimeHR = process.hrtime();

		request.get({url : 'http://localhost:8080/greeting?name=Maarten'}
        , function (error, response, body) {
			if (!error && response.statusCode == 200) {
				var durationHR = process.hrtime(startTimeHR);
				//mylogger(pid+"\tRequest end. Duration in ms:\t%d", (durationHR[0]*1000)+(durationHR[1] / 1000000));
                mylogger("MEASURE: %d", (durationHR[0]*1000)+(durationHR[1] / 1000000));
				callback();
			} else {
				mylogger("INFO: "+pid+"\tError! " + JSON.stringify(error));
				callback();
			}
		});
	};
    
    async.doWhilst(requestfunc,
    function(results, err) {
        return true;
    },
    function(err, results) {
        mylogger("INFO: "+"Error occurred", err, results)
    }
    );
}
