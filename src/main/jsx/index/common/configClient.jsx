var http = require('../../common/httpClient');

const configApiPath = "api/v1/config/"

module.exports = {
  getConfig: function(callback){
    http.get(configApiPath, function(body){
      callback(body);
    });
  }
}

