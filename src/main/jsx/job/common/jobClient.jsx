var http = require('http');

module.exports = {
  getJobStats: function(callback){
    this.get("stats", function(body){
      callback(body);
    });
  },
  getJobs: function(param, callback){
    var path = "?" + Object.keys(param).map(function(k){
      return k + "=" + encodeURIComponent(param[k]);
    }).join("&");
    this.get(path, function(body){
      callback(body);
    });
  },
  getJob: function(jobId, callback){
    jobId = encodeURIComponent(jobId);
    this.get(jobId, function(body){
      callback(body);
    });
  },
  getHistory: function(jobId, size, callback){
    jobId = encodeURIComponent(jobId);
    var path = jobId + "/histories?size=" + size
    this.get(path, function(body){
      callback(body);
    });
  },
  updateJobState: function(jobId, state, option, callback){
    jobId = encodeURIComponent(jobId);
    this.request_with_body(jobId, "PUT", {state : state, option: option}, function(body){
      callback(body);
    });
  },
  updateJobs: function(jobIds, postStatus, options, callback){
    postStatus.job_ids = jobIds;
    this.request_with_body("/", "PUT", postStatus, function(body){
      callback(body);
    });
  },
  get: function(path, callback){
    var req = this.request(path, "GET", callback);
    req.end();
  },
  request_with_body: function(path, method, data, callback){
    var jsonData = JSON.stringify(data);
    var options = {
        headers: {
          'Content-Type':'application/json; ;charset="UTF-8"',
          'Content-Length':jsonData.length,
        }
    };
    var req = this.request(path, method, callback, options);
    req.write(jsonData);
    req.end();
  },
  request: function(path, method, callback, options){
    if(typeof options === "undefined") options ={headers:{}};
    options.path = "/api/v1/jobs/" + path;
    options.method = method;
    options.headers["Accept"] = "text/json";
    return http.request(options, function(res){
      var body = '';
      res.setEncoding('utf8');
      res.on("data", function(chunk){
        body += chunk;
      });
      res.on("end", function(){
        var data = JSON.parse(body);
        if (res.statusCode == 200) callback(data);
      });
    }).on("error", function(e) {
      console.log("Got error: " + e.message);
      alert(e.message);
    });
  }
}

