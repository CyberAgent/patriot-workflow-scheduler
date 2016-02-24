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
    if(typeof options === "undefined") options ={headers:{}};
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
    }).on("error", function(e) {
      alert(e.message);
    });
  }
}

