var http = require('../../common/httpClient');

const jobApiPath = "/api/v1/jobs/";
module.exports = {
  getJobStats: function(callback){
    http.get(jobApiPath + "stats", function(body){
      callback(body);
    });
  },
  getJobs: function(param, callback){
    var path = "?" + Object.keys(param).map(function(k){
      return k + "=" + encodeURIComponent(param[k]);
    }).join("&");
    http.get(jobApiPath + path, function(body){
      callback(body);
    });
  },
  getJob: function(jobId, callback){
    jobId = encodeURIComponent(jobId);
    http.get(jobApiPath + jobId, function(body){
      callback(body);
    });
  },
  getHistory: function(jobId, size, callback){
    jobId = encodeURIComponent(jobId);
    var path = jobId + "/histories?size=" + size
    http.get(jobApiPath + path, function(body){
      callback(body);
    });
  },
  getGraph: function(jobId, pDepth, cDepth, callback){
    jobId = encodeURIComponent(jobId);
    var path = jobId + "/graph?p_depth=" + pDepth + "&c_depth=" + cDepth;
    http.get(jobApiPath + path, function(body){
      callback(body);
    });
  },
  updateJobState: function(jobId, state, option, callback){
    jobId = encodeURIComponent(jobId);
    http.request_with_body(jobApiPath + jobId, "PUT", {state : state, option: option}, function(body){
      callback(body);
    });
  },
  updateJob: function(job, callback){
    http.request_with_body(jobApiPath, "POST", job, function(body){
      callback(body);
    });
  },
  updateJobs: function(jobIds, postStatus, options, callback){
    postStatus.job_ids = jobIds;
    http.request_with_body(jobApiPath, "PUT", postStatus, function(body){
      callback(body);
    });
  },
  deleteJobs: function(jobIds, options, callback){
    // client and/or server may not support DELETE body
    var path = jobApiPath + "?job_ids=" + encodeURIComponent(JSON.stringify(jobIds));
    http.request_with_body(path, "DELETE", {}, function(body){
      callback(body);
    });
  }
}

