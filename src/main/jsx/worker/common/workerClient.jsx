var http = require('../../common/httpClient');

const workerApiPath = "api/v1/workers/"

module.exports = {
  getWorkers: function(callback){
    http.get(workerApiPath, function(body){
      callback(body);
    });
  }
}

