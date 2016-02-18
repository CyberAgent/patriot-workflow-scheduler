var React = require('react');
var JobUtil = require('./jobUtil');
var JobClient = require('./jobClient');

module.exports = React.createClass({
  mixins : [JobUtil, JobClient],
  getInitialState : function(){
    return {jobState : this.props.currentState, with_subsequent : false };
  },
  componentWillReceiveProps : function(newProps){
    this.setState({jobState : newProps.currentState});
  },
  handleSubmit : function(){
    this.updateJobState(this.props.jobId, this.state.jobState, {with_subsequent: this.state.with_subsequent}, function(){
      this.props.completionHandler(this.props.jobId);
    }.bind(this));
  },
  handleUpdate : function(event){
    this.setState({jobState: event.target.value});
  },
  handleWithSubsequentUpdate: function(event){
    this.setState({with_subsequent: event.target.value});
  },
  render : function(){
    return (
      <form onSubmit={this.handleSubmit} >
        <table>
          <tbody>
            <tr>
              <td>
                <select className="form-control"  onChange={this.handleUpdate} value={this.state.jobState} >
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
                <button type='submit' className="btn btn-primary"> change state </button>
              </td>
            </tr>
          </tbody>
        </table>
      </form>
    );
  }
});

