var React = require('react');
var JobList = require('./jobList');
var JobUtil = require('./common/jobUtil');
var JobClient = require('./common/jobClient');

import { hashHistory, Link } from 'react-router'
import { formatPattern } from 'react-router/lib/PatternUtils';

module.exports = React.createClass({
  mixins : [JobUtil, JobClient],
  getInitialState : function(){
    return { offset : 0, limit : 50, jobs : [], filter_exp : "" };
  },
  componentWillMount: function(){
    var param = this.parseQuery(this.props.location.query);
    param.state = parseInt(this.props.params.state);
    this.fetchJobs(param);
  },
  componentWillReceiveProps: function(nextProps){
    var param = this.parseQuery(nextProps.location.query);
    param.state = parseInt(nextProps.params.state);
    this.fetchJobs(param);
  },
  parseQuery: function(query){
    var param = {};
    param.offset = typeof(query.offset) == "undefined" ? 0 : parseInt(query.offset);
    param.limit = typeof(query.limit) == "undefined" ? 50 : parseInt(query.limit);
    param.filter_exp = typeof(query.filter_exp) == "undefined" ? "": query.filter_exp;
    return param;
  },
  handleUpdateFilter: function(event){
    this.setState({filter_exp: event.target.value});
  },
  handleFilterSubmit: function(){
    var param = {
      state  : parseInt(this.props.params.state),
      filter_exp : this.state.filter_exp
    };
    this.fetchJobs(param);
  },
  fetchJobs: function(param){
    if(param.offset == NaN ) param.offset = 0;
    if(param.limit == NaN ) param.limit = 50;
    this.getJobs(param, function(jobs){
      param.jobs = jobs;
      this.setState(param);
    }.bind(this));
  },
  render: function(){
    var offset = parseInt(this.state.offset);
    var limit = parseInt(this.state.limit);
    var prevOffset = offset > limit ? offset -limit : 0;
    var nextOffset = limit > this.state.jobs.length ? offset : offset + limit;
    return (
      <div>
        <div className="clearfix">
          <h1> {this.name_of_state(this.props.params.state)} Jobs </h1>
          <form className="inline">
            <input className="form-control" type="text" placeholder="filter by job_id" onChange={this.handleUpdateFilter} value={this.state.filter_exp}/>
            <button className="btn btn-primary" onClick={this.handleFilterSubmit}> search </button>
          </form>
        </div>
        <JobList jobs={this.state.jobs} path={this.props.location.pathname} hasDeleteButton={parseInt(this.props.params.state) == -2} />
        <div className ="pager">
          <ul>
            <li className={offset > 0 ? "previous" : "previous disabled"}>
              <Link to={{pathname: "/job/list/" + this.props.params.state, query: {filter_exp: this.state.filter_exp, offset: prevOffset, limit: limit}}}>prev</Link>
            </li>
            <li className={this.state.jobs.length == limit ? "next" : "next disabled"}>
              <Link to={{pathname: "/job/list/" + this.props.params.state, query: {filter_exp: this.state.filter_exp, offset: nextOffset, limit: limit}}}>next</Link>
            </li>
          </ul>
        </div>
      </div>
    );
  }
});

