var React = require('react');
var WorkerClient = require('./common/workerClient');
import { Router, Route, Link, IndexRoute, IndexRedirect } from 'react-router'

module.exports = React.createClass({
  mixins: [WorkerClient],
  getInitialState: function(){
    return {
      workers: []
    };
  },
  componentWillMount: function(){
    this.getWorkers(function(workers){
      this.setState({
        workers: workers
      });
    }.bind(this))
  },
  render: function () {
    return (
      <div className="container">
        <ul>
          {this.state.workers.map(function(worker){
            return (<li key={worker}> {worker} </li>);
          })}
        </ul>
      </div>
      );
  }
});

