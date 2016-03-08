import React from 'react';
import ReactDOM from 'react-dom';
import { Router, Route, Link, IndexRoute, IndexRedirect, browserHistory } from 'react-router'

import Index from './index';
import JobManager from './job/jobManager';
import JobListView from './job/jobListView';
import JobView from './job/jobView';

import WorkerManager from './worker/workerManager';
import WorkerView from './worker/workerView';

var SchedulerManager = React.createClass({
  getInitialState: function() {
    return { currentManager: JobManager };
  },
  render: function () {
    return (
      <div>
        <nav className="navbar navbar-inverse">
          <div className="container-fluid">
            <div className="navbar-header">
              <Link to="/" className="navbar-brand">Patriot Workflow Scheduler</Link>
            </div>
            <ul className="nav navbar-nav">
              <li> <Link to="/job"> Job </Link> </li>
              <li> <Link to="/worker"> Worker </Link> </li>
            </ul>
          </div>
        </nav>
        {this.props.children}
      </div>
    );
  }
});

ReactDOM.render((
  <Router history={browserHistory}>
    <Route path="/" component={SchedulerManager}>
      <IndexRoute component={Index} />
      <Route path="job" component={JobManager}>
        <IndexRedirect to="/job/list/4" />
        <Route path="list/:state" component={JobListView}/>
        <Route path="detail/:jobId" component={JobView}/>
      </Route>
      <Route path="worker" component={WorkerManager}>
        <IndexRedirect to="/worker/this" />
        <Route path="this" component={WorkerView}/>
      </Route>
    </Route>
 </Router>),
  document.getElementById('mainContent')
);


