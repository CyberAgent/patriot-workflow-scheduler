var http = require('http');

module.exports = {
  get: function(path, callback){
    var req = this.request(path, "GET", callback);
    req.end();
  },
  request_with_body: function(path, method, data, callback){
    var jsonData = JSON.stringify(data);
    var options = {
        headers: {
          'Content-Type':'application/json;charset=utf-8',
          'Content-Length':jsonData.length,
        }
    };
    var req = this.request(path, method, callback, options);
    req.write(jsonData);
    req.end();
  },
  request: function(path, method, callback, options){
    if(typeof options === "undefined") options ={};
    if(typeof options.headers === "undefined") options.headers = {};
    if(typeof options.e_callback === "undefined") options.e_callback = function(e){ alert(e.message); }
    options.path = path;
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
    }).on("error", options.e_callback);
  }
}

