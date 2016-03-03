import React from 'react';
import WorkerClient from './worker/common/workerClient';
import { Router, Route, Link, IndexRoute, IndexRedirect } from 'react-router'

module.exports = React.createClass({
  mixins: [WorkerClient],
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
        host: conf["host"],
        version: conf["version"],
        workerClass: conf["class"],
        startedAt: conf["started_at"]
      });
    }.bind(this))
  },
  render: function () {
    return (
      <div className="container">
        <h2> worker @ {this.state.host} </h2>
        <table className="table table-bordered tabel-striped">
          <tbody>
            <tr><td>VERSION :</td><td>{this.state.version} </td></tr>
            <tr><td>CLASS :</td><td> {this.state.workerClass} </td></tr>
            <tr><td> STARTED AT :</td><td> {this.state.startedAt} </td></tr>
          </tbody>
        </table>
      </div>
      );
  }
});

