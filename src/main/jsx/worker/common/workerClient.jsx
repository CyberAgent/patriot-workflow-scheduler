var http = require('../../common/httpClient');

const workerApiPath = "/api/v1/workers/"

module.exports = {
  getConfig: function(callback){
    http.get(workerApiPath+"this", function(body){
      callback(body);
    });
  },
  getWorkers: function(callback){
    http.get(workerApiPath, function(body){
      callback(body);
    });
  }
}

