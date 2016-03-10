var React = require('react');

module.exports = {
  name_of_state : function(state){
    if (typeof(state) == "string") state = parseInt(state);
    switch(state){
      case -2 : return "DISCARDED"
      case -1 : return "INITIATING"
      case 0  : return "SUCCEEDED"
      case 1  : return "WAITING"
      case 2  : return "RUNNING"
      case 3  : return "SUSPENDED"
      case 4  : return "FAILED"
      default : return "unknown state: " + state
    }
  },
  name_of_exitcode : function(exit_code){
    switch(exit_code){
      case 0  : return "SUCCEEDED"
      case 1  : return "FAILED"
      case null:return ""
      default : return "unknown exit code: " + exit_code
    }
  }
}

