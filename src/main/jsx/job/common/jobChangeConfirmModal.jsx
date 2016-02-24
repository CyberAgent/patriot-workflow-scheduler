var React = require('react');
var Modal = require('react-modal');

module.exports = React.createClass({
  getInitialState: function() {
    return { modalIsOpen: this.props.modalIsOpen };
  },
  componentWillReceiveProps: function(newProps){
    this.setState({modalIsOpen: newProps.modalIsOpen});
  },
  handleSubmit: function(){
    this.props.submitHandler();
  },
  handleClose: function(){
    this.props.closeHandler();
  },
  render: function() {
            console.log(this.props);
    return (
      <div>
        <Modal
          isOpen={this.state.modalIsOpen}
          onRequestClose={this.handleClose}>
          <h2>Job Update Confirmation</h2>
          <table className="table table-bordered table-striped">
            <tbody>
              {this.props.jobIds.map(function(jobId){
                 return (
                   <tr key={jobId}>
                     <td>{jobId}</td><td>{this.props.deltaDescription}</td>
                   </tr>
                 );
              }.bind(this))}
            </tbody>
          </table>
          <button className="btn btn-primary"  onClick={this.handleSubmit}>submit</button>
          <button className="btn btn-secondary" onClick={this.handleClose}>cancel</button>
        </Modal>
      </div>
    );
  }
});
