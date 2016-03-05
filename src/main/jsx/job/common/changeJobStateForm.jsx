import React from 'react';
import JobUtil from './jobUtil';
import JobClient from './jobClient';
import JobChangeConfirmModal from './jobChangeConfirmModal';

module.exports = React.createClass({
  mixins : [JobUtil, JobClient],
  contextTypes: {
    router: React.PropTypes.object.isRequired
  },
  getInitialState : function(){
    return {
      postState : this.props.currentState,
      with_subsequent : false,
      modalIsOpen : false
    };
  },
  componentWillReceiveProps : function(newProps){
    this.setState({postState : newProps.currentState});
  },
  submitNewState : function(){
    this.updateJobState(this.props.jobId, this.state.postState, {with_subsequent: this.state.with_subsequent}, function(){
      this.closeModal();
      this.context.router.replace("/job/detail/" + encodeURIComponent(this.props.jobId));
    }.bind(this));
  },
  openModal : function(){
    this.setState({modalIsOpen: true});
  },
  closeModal : function(){
    this.setState({modalIsOpen: false});
  },
  handleUpdate : function(event){
    this.setState({postState: event.target.value});
  },
  handleWithSubsequentUpdate: function(event){
    this.setState({with_subsequent: event.target.value});
  },
  render : function(){
    var deltaMessage = "state = " + this.name_of_state(this.state.postState);
    if(this.state.with_subsequent) deltaMessage = deltaMessage + " with subsequent jobs";
    return (
      <div>
  <JobChangeConfirmModal
    modalIsOpen = {this.state.modalIsOpen}
    submitHandler = {this.submitNewState}
    closeHandler = {this.closeModal}
    jobIds = {[this.props.jobId]}
    deltaDescription={deltaMessage}
  />
      <table>
        <tbody>
          <tr>
            <td>
              <select className="form-control"  onChange={this.handleUpdate} value={this.state.postState} >
                <option value={1} > WAIT </option>
                <option value={0} > SUCCEEDED </option>
                <option value={3} > SUSPEND </option>
                <option value={4} > FAILED </option>
                <option value={-2} > DISCARDED </option>
              </select>
            </td><td>
              <select className="form-control"  onChange={this.handleWithSubsequentUpdate} value={this.state.with_subsequet} >
                <option value={false} > ONLY THIS </option>
                <option value={true} > WITH SUBSEQUENT </option>
              </select>
            </td><td>
              <button type='submit' className="btn btn-primary" onClick={this.openModal}> change state </button>
            </td>
          </tr>
        </tbody>
      </table>
      </div>
    );
  }
});

