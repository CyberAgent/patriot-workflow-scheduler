var React = require('react');
var ConfigClient = require('./common/configClient');
import { Router, Route, Link, IndexRoute, IndexRedirect } from 'react-router'

module.exports = React.createClass({
  mixins: [ConfigClient],
  getInitialState: function(){
    return {
      version: "",
      workerClass: "",
      startedAt: ""
    };
  },
  componentWillMount: function(){
    this.getConfig(function(conf){
      this.setState({
        version: conf["version"],
        workerClass: conf["class"],
        startedAt: conf["started_at"]
      });
    }.bind(this))
  },
  render: function () {
    return (
      <div className="container">
        <ul>
          <li> VERSION : {this.state.version} </li>
          <li> CLASS : {this.state.workerClass} </li>
          <li> STARTED AT : {this.state.startedAt} </li>
        </ul>
      </div>
      );
  }
});

