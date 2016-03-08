var React = require('react');
var JobListView = require('./jobListView');
var JobView = require('./jobView');
var JobClient = require('./common/jobClient');
var Router = require('react-router');
var DefaultRoute = Router.DefaultRoute;
var Link = Router.Link;
var Route = Router.Route;
var RouteHandler = Router.RouteHandler;

const states = ["0", "1", "2", "3", "4", "-1", "-2"];

module.exports = React.createClass({
  mixins: [JobClient],
  getInitialState: function() {
    return {
      viewState : { type: "list", state: 4 },
      jobStats : {
        "0" : "***",
        "1" : 0, "2" : 0, "3" : 0, "4" : 0,
        "-1" : 0, "-2": 0
      }
    };
  },
  componentWillMount: function(){
    this.updateJobStats({});
  },
  componentWillReceiveProps: function(){
    this.updateJobStats({});
  },
  updateJobStats: function(otherState){
    this.getJobStats(function(stats){
      if(stats["0"] == undefined) stats["0"] = "***";
      for (var i = 0; i < states.length ; i++){
        if(stats[states[i]] == undefined){
          stats[states[i]] = states[i] == "0" ? "***" : 0;
        }
      }
      otherState.jobStats = stats
      this.setState(otherState);
    }.bind(this));
  },
  render: function(){
    var children = this.props.children;
    return (
    <div className="container">
      <div className="row">
        <div className = "col-md-3 well well-lg">
          <h3> #Jobs </h3>
          <table className="table">
            <tbody>
              <tr>
                <td>Succeeded  :</td><td><Link to="/job/list/0">{this.state.jobStats["0"]}</Link></td>
              </tr><tr>
                <td>Initiating :</td><td><Link to="/job/list/-1">{this.state.jobStats["-1"]}</Link></td>
              </tr><tr>
                <td>Waiting    :</td><td><Link to="/job/list/1">{this.state.jobStats["1"]}</Link></td>
              </tr><tr>
                <td>Running    :</td><td><Link to="/job/list/2">{this.state.jobStats["2"]}</Link></td>
              </tr><tr>
                <td>Suspended  :</td><td><Link to="/job/list/3">{this.state.jobStats["3"]}</Link></td>
              </tr><tr>
                <td>Failed     :</td><td><Link to="/job/list/4">{this.state.jobStats["4"]}</Link></td>
              </tr><tr>
                <td>Discarded  :</td><td><Link to="/job/list/-2">{this.state.jobStats["-2"]}</Link></td>
              </tr>
            </tbody>
          </table>
        </div>
        <div className="col-md-9">
          {children}
        </div>
      </div>
    </div>
    );
  }
});

