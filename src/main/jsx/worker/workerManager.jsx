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
      <div className="row">
        <div className = "col-md-3 well well-lg">
          <h3> Workers </h3>
          <table className="table">
            <tbody>
              <tr>
                <td><Link to="/worker/this">this worker</Link></td>
              </tr>
              {this.state.workers.map(function(w){
                var addr = "http://" + w.host + ":" + w.port;
                return (<tr key={w.host}><td><a href={addr} > {w.host} </a></td></tr>);
              })}
            </tbody>
          </table>
        </div>
        <div className="col-md-9">
          {this.props.children}
        </div>
      </div>
    </div>
      );
  }
});

