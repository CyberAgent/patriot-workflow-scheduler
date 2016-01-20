var React = require('react');
var ReactDOM = require('react-dom');
import { Router, Route, Link, IndexRedirect } from 'react-router'
var history = require('react-router').hashHistory

var JobManager = require('./job/jobManager');
var JobListView = require('./job/jobListView');
var JobView = require('./job/jobView');

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
      <IndexRedirect to="/job/list/4" />
      <Route path="job" component={JobManager}>
        <IndexRedirect to="/job/list/4" />
        <Route path="list/:state" component={JobListView}/>
        <Route path="detail/:jobId" component={JobView}/>
      </Route>
    </Route>
 </Router>),
  document.getElementById('mainContent')
);


