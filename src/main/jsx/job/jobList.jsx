var React = require('react');
var JobUtil = require('./common/jobUtil');
var JobClient = require('./common/jobClient');
import { Router, Route, Link, IndexRoute } from 'react-router'
import { formatPattern } from 'react-router/lib/PatternUtils';

module.exports = React.createClass({
  mixins : [JobUtil, JobClient],
  getInitialState: function(){
    return {selected: {}, allChecked: false, nextState: 0};
  },
  handleAllChecked: function(){
    var allChecked = !this.state.allChecked;
    var selected = {}
    for(var i = 0 ; i < this.props.jobs.length; i++){
      var jobId = this.props.jobs[i].job_id
      selected[jobId] = allChecked;
    }
    this.setState({allChecked: allChecked, selected: selected});
  },
  jobSelectionHandler: function(jobId){
    return function(){
      var selected = this.state.selected;
      selected[jobId] = typeof(selected[jobId]) == "undefined" ? true : !selected[jobId];
      this.setState({allChecked: false, selected: selected});
    }.bind(this);
  },
  handleNextStateUpdate: function(event){
    this.setState({nextState: event.target.value});
  },
  handleSubmit: function(){
    var jobIds = [];
    Object.keys(this.state.selected).forEach(function(jobId){
      jobIds.push(jobId);
    });
    if(jobIds.length > 0){
      this.updateJobs(jobIds, {state: this.state.nextState}, function(){
        console.log(this.props);
      }.bind(this));
    }else{
      alert("jobs are not selected");
    }
  },
  render : function(){
    return (
      <div className="alt-table-responsive">
        <table className='table table-bordered table-striped'>
          <thead>
            <tr>
              <th className="col-md-1">
                <input className="form-control" type="checkbox" onChange={this.handleAllChecked} checked={this.state.allChecked}></input>
              </th>
              <th className="col-md-9"> Job ID </th>
              <th className="col-md-2"> State </th>
            </tr>
          </thead>
          <tbody>
            {this.props.jobs.map(function(job){
              return (<tr key={job.job_id}>
                        <td><input className="form-control" type="checkbox" onChange={this.jobSelectionHandler(job.job_id)} checked={this.state.selected[job.job_id]}></input> </td>
                        <td><Link to={formatPattern("/job/detail/:job_id", {job_id: job.job_id})}> {job.job_id} </Link> </td>
                        <td> {this.name_of_state(job.state)} </td>
                      </tr> );
            }.bind(this))}
          </tbody>
        </table>
        <form onSubmit={this.handleSubmit} >
          <table>
            <tbody>
              <tr>
                <td>
                  <select className="form-control"  onChange={this.handleNextStateUpdate} value={this.state.nextState} >
                    <option value={1} > WAIT </option>
                    <option value={0} > SUCCEEDED </option>
                    <option value={3} > SUSPEND </option>
                    <option value={4} > FAILED </option>
                    <option value={-2} > DISCARDED </option>
                  </select>
                </td><td>
                  <button type='submit' className="btn btn-primary"> change state </button>
                </td>
              </tr>
            </tbody>
          </table>
        </form>
      </div>
    );
  }
});

