var React = require('react');
var ReactDOM = require('react-dom');
import { Router, Route, Link, IndexRoute, IndexRedirect } from 'react-router'
var history = require('react-router').hashHistory

var Index = require('./index/index');
var JobManager = require('./job/jobManager');
var JobListView = require('./job/jobListView');
var JobView = require('./job/jobView');
var WorkerManager = require('./worker/workerManager');

var SchedulerManager = React.createClass({
  getInitialState: function() {
    return { currentManager: JobManager };
  },
  render: function () {
    return (
      <div>
        <div className="navbar navbar-inverse">
          <div className="container-fluid">
            <a href="./" className="navbar-brand">Patriot Workflow Scheduler</a>
            <Link to="job" className="navbar-brand"> Job </Link>
            <Link to="worker" className="navbar-brand"> Worker </Link>
          </div>
        </div>
        <div>
          {this.props.children}
        </div>
      </div>
    );
  }
});

ReactDOM.render((
  <Router history={history}>
    <Route path="/" component={SchedulerManager}>
      <IndexRoute component={Index} />
      <Route path="job" component={JobManager}>
        <IndexRedirect to="/job/list/4" />
        <Route path="list/:state" component={JobListView}/>
        <Route path="detail/:jobId" component={JobView}/>
      </Route>
      <Route path="worker" component={WorkerManager}>
      </Route>
    </Route>
 </Router>),
  document.getElementById('mainContent')
);


