import React from 'react';
import JobUtil from './common/jobUtil';
import JobClient from './common/jobClient';
import JobChangeConfirmModal from './common/jobChangeConfirmModal';
import { Router, Route, Link, IndexRoute } from 'react-router'
import { formatPattern } from 'react-router/lib/PatternUtils';

module.exports = React.createClass({
  mixins : [JobUtil, JobClient],
  contextTypes: {
    router: React.PropTypes.object.isRequired
  },
  getInitialState: function(){
    return {
      selected: {},
      allChecked: false,
      postState: 0,
      updateModalIsOpen : false,
      deleteModalIsOpen : false
    };
  },
  handleAllChecked: function(){
    var allChecked = !this.state.allChecked;
    var selected = {}
    if(allChecked){
      for(var i = 0 ; i < this.props.jobs.length; i++){
        var jobId = this.props.jobs[i].job_id
        selected[jobId] = allChecked;
      }
    }
    this.setState({allChecked: allChecked, selected: selected});
  },
  jobSelectionHandler: function(jobId){
    return function(){
      var selected = this.state.selected;
      if (typeof(selected[jobId]) == "undefined"){
        selected[jobId] = true;
      }else{
        delete selected[jobId];
      }
      this.setState({allChecked: false, selected: selected});
    }.bind(this);
  },
  handlePostStateUpdate: function(event){
    this.setState({postState: event.target.value});
  },
  handleUpdate: function(){
    var jobIds = this.getSelectedJobIds();
    if(jobIds.length > 0){
      this.setState({updateModalIsOpen : true });
    }else{
      alert("jobs are not selected");
    }
  },
  closeUpdateModal: function(){
    this.setState({updateModalIsOpen : false });
  },
  requestUpdate: function(){
    var jobIds = this.getSelectedJobIds();
    this.updateJobs(jobIds, {state: this.state.postState}, {}, function(){
      this.context.router.push(this.props.path);
    }.bind(this));
    this.setState({updateModalIsOpen : false, selected : {}, allChecked: false });
  },
  handleDelete: function(){
    var jobIds = this.getSelectedJobIds();
    if(jobIds.length > 0){
      this.setState({deleteModalIsOpen : true });
    }else{
      alert("jobs are not selected");
    }
  },
  closeDeleteModal: function(){
    this.setState({deleteModalIsOpen : false });
  },
  requestDelete: function(){
    var jobIds = this.getSelectedJobIds();
    this.deleteJobs(jobIds, {}, function(){
      this.context.router.push(this.props.path);
    }.bind(this));
    this.setState({deleteModalIsOpen : false, selected : {}, allChecked: false });
  },
  getSelectedJobIds: function(){
    var jobIds = [];
    Object.keys(this.state.selected).forEach(function(jobId){
      if(this.state.selected[jobId]) jobIds.push(jobId);
    }.bind(this));
    return jobIds;
  },
  render : function(){
    return (
      <div className="alt-table-responsive">
        <JobChangeConfirmModal
          modalIsOpen = {this.state.updateModalIsOpen}
          submitHandler = {this.requestUpdate}
          closeHandler = {this.closeUpdateModal}
          jobIds = {this.getSelectedJobIds()}
          deltaDescription={`state = ${this.name_of_state(this.state.postState)}`}
        />
        <JobChangeConfirmModal
          modalIsOpen = {this.state.deleteModalIsOpen}
          submitHandler = {this.requestDelete}
          closeHandler = {this.closeDeleteModal}
          jobIds = {this.getSelectedJobIds()}
          deltaDescription="DELETE"
        />
        <table className='table table-bordered table-striped'>
          <thead>
            <tr>
              <th className="col-md-1">
                <input type="checkbox" onChange={this.handleAllChecked} checked={this.state.allChecked}></input>
              </th>
              <th className="col-md-9"> Job ID </th>
              <th className="col-md-2"> State </th>
            </tr>
          </thead>
          <tbody>
            {this.props.jobs.map(function(job){
              return (<tr key={job.job_id}>
                        <td onClick={this.jobSelectionHandler(job.job_id)}><input className="form-control small-checkbox" type="checkbox" checked={this.state.selected[job.job_id]}></input> </td>
                        <td><Link to={formatPattern("/job/detail/:job_id", {job_id: job.job_id})}> {job.job_id} </Link> </td>
                        <td> {this.name_of_state(job.state)} </td>
                      </tr> );
            }.bind(this))}
          </tbody>
        </table>
        <table>
          <tbody>
            <tr>
              <td>
                <select className="form-control"  onChange={this.handlePostStateUpdate} value={this.state.postState} >
                  <option value={1} > WAIT </option>
                  <option value={0} > SUCCEEDED </option>
                  <option value={3} > SUSPEND </option>
                  <option value={4} > FAILED </option>
                  <option value={-2} > DISCARDED </option>
                </select>
              </td><td>
                <button type='submit' onClick={this.handleUpdate} className="btn btn-primary"> change state </button>
              </td><td>
                {this.props.hasDeleteButton ? <button type='submit' onClick={this.handleDelete} className="btn btn-danger"> delete </button> : null }
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    );
  }
});

