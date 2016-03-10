import React from 'react';
import JobList from './jobList';
import JobClient from './common/jobClient';
import JobUtil from './common/jobUtil';
import ChangeJobStateForm from './common/changeJobStateForm';

import { formatPattern } from 'react-router/lib/PatternUtils';

import DependencyGraph from './dependencyGraph';
import NumericInput from 'react-numeric-input';
import Tab from 'react-tabs/lib/components/Tab';
import Tabs from 'react-tabs/lib/components/Tabs';
import TabList from 'react-tabs/lib/components/TabList';
import TabPanel from 'react-tabs/lib/components/TabPanel';

const commonJobAttributes = [
  "COMMAND_CLASS", "update_id", "state", "priority", "start_datetime", "exec_host", "exec_node",
  "products", "requisites", "consumers", "producers"
  ];

const tabIndex = {
  "TAB_INDEX_DEFAULT": 0,
  "TAB_INDEX_GRAPH": 1
};

module.exports = React.createClass({
  mixins : [JobUtil, JobClient],
  contextTypes: {
    router: React.PropTypes.object.isRequired
  },
  getInitialState : function(){
    return {
      job : {},
      history : [],
      dependencyProducerDepth : 2,
      dependencyConsumerDepth : 2,
      tabIndex : tabIndex["TAB_INDEX_DEFAULT"]
    };
  },
  componentWillMount: function(){
    this.updateJob(this.props.params.jobId);
  },
  componentWillReceiveProps: function(nextProps){
    this.updateJob(nextProps.params.jobId);
  },
  componentWillUpdate: function(nextProps, newState){
  },
  updateJob : function(jobId){
    this.getJob(jobId, function(job){
      this.getHistory(jobId, 3, function(history){
        this.setState({job: job, history: history });
      }.bind(this));
    }.bind(this));
  },
  handleTabSelect: function(index, last) {
    this.setState({tabIndex: index});
  },
  handleChangeProducerGraphDepth: function(val) {
    this.setState({dependencyProducerDepth: val});
  },
  handleChangeConsumerGraphDepth: function(val) {
    this.setState({dependencyConsumerDepth: val});
  },
  render : function(){
    var update_at = new Date(this.state.job.update_id * 1000).toString();
    var commandAttributes = [];
    var tdStyle = {wordWrap:"break-word", wordBreak:"break-all"}
    Object.keys(this.state.job).forEach(function(key){
      if( commonJobAttributes.indexOf(key) < 0 ){
        var obj = this.state.job[key];
        if(obj instanceof Array){
          obj.forEach(function(e,i,a){
            commandAttributes.push((
              <tr key={key+i}>
                <td className="original main">{i==0 ? "" : key}</td>
                <td style={tdStyle} colSpan="3">{JSON.stringify(e)}</td>
              </tr>
            ));
          });
        }else{
          commandAttributes.push((
            <tr key={key}>
              <td className="original main">{key}</td>
              <td style={tdStyle} colSpan="3">{JSON.stringify(obj)}</td>
            </tr>
          ));
        }
      }
    }.bind(this));

    var producers, consumers;
    if(this.state.job.producers != undefined ){
      producers = (
        <div>
          <h4> Before </h4>
          <JobList jobs={this.state.job.producers} path={this.props.location.pathname} hasDeleteButton={false} />
        </div>
      );
    }
    if(this.state.job.consumers != undefined ){
      consumers = (
        <div>
          <h4> After </h4>
          <JobList jobs={this.state.job.consumers} path={this.props.location.pathname} hasDeleteButton={false} />
        </div>
      );
    }

    return (
<div>
  <div style={{position: "relative"}}>
    <Tabs
      onSelect={this.handleTabSelect}
      selectedIndex={this.state.tabIndex}
    >
      <TabList>
        <Tab>Job Info</Tab>
        <Tab>Graph</Tab>
      </TabList>

      <TabPanel>
        <div><h1 className="original">{this.props.params.jobId}</h1></div>
        <h3> Job Info. </h3>
        <ChangeJobStateForm jobId={this.props.params.jobId} currentState={this.state.job.state} />
        <table className="table table-bordered" style={{tableLayout:"fixed"}}>
          <tbody>
            <tr>
              <td className="original main">Command Class</td><td colSpan='3'>{this.state.job.COMMAND_CLASS}</td>
            </tr><tr>
              <td className="original main">Updated at</td><td>{update_at}</td>
              <td className="original main">State</td><td>{this.name_of_state(this.state.job.state)}</td>
            </tr><tr>
              <td className="original main">Priority</td><td>{this.state.job.priority}</td>
              <td className="original main">Start After</td><td>{this.state.job.start_datetime}</td>
            </tr><tr>
              <td className="original main">Host</td><td>{this.state.job.exec_host}</td>
              <td className="original main">Node</td><td>{this.state.job.exec_node}</td>
            </tr><tr>
              <td className="original main">Produced Products</td><td colSpan='3'>{this.state.job.products}</td>
            </tr><tr>
              <td className="original main">Required Products</td><td colSpan='3'>{this.state.job.requisites}</td>
            </tr><tr>
              <td className="original main" colSpan='4'> content </td>
            </tr>
            {commandAttributes.map(function(e){return e})}
          </tbody>
        </table>
        <h3> Execution History </h3>
        <table className="table table-borderd">
          <thead>
            <tr>
              <th> host </th>
              <th> node </th>
              <th> begin_at </th>
              <th> end_at </th>
              <th> result </th>
              <th> description </th>
            </tr>
          </thead>
          <tbody>
            {this.state.history.map(
              function(history){
                return (<tr key={history.begin_at} >
                  <td> {history.host} </td>
                  <td> {history.node} </td>
                  <td> {history.begin_at} </td>
                  <td> {history.end_at} </td>
                  <td> {this.name_of_exitcode(history.exit_code)} </td>
                  <td> {history.description} </td>
                </tr>);
              }.bind(this)
            )}
          </tbody>
        </table>
        <h3> Dependency </h3>
        {producers}
        {consumers}
      </TabPanel>
      <TabPanel>
        <div style={{width: "50%", textAlign: "center", display:"inline-block"}}>
          &lt;&lt; Producer Dependency Depth 
          <NumericInput min={0} max={4} size={2} onChange={this.handleChangeProducerGraphDepth} value={this.state.dependencyProducerDepth} mobile valueAsNumber />
        </div>
        <div style={{width: "50%", textAlign: "center", display:"inline-block"}}>
          &gt;&gt; Consumer Dependency Depth 
          <NumericInput min={0} max={4} size={2} onChange={this.handleChangeConsumerGraphDepth} value={this.state.dependencyConsumerDepth} mobile valueAsNumber />
        </div>

        <div id="statePanel">
          <div style={{display:"inline-block", verticalAlign:"middle"}}>DISCARDED</div>
          <div className="stateExplanation status DISCARDED"></div>
          <br />
          <div style={{display:"inline-block", verticalAlign:"middle"}}>INITIATING</div>
          <div className="stateExplanation status INITIATING"></div>
          <br />
          <div style={{display:"inline-block", verticalAlign:"middle"}}>SUCCEEDED</div>
          <div className="stateExplanation status SUCCEEDED"></div>
          <br />
          <div style={{display:"inline-block", verticalAlign:"middle"}}>WAITING</div>
          <div className="stateExplanation status WAITING"></div>
          <br />
          <div style={{display:"inline-block", verticalAlign:"middle"}}>RUNNING</div>
          <div className="stateExplanation status RUNNING"></div>
          <br />
          <div style={{display:"inline-block", verticalAlign:"middle"}}>SUSPENDED</div>
          <div className="stateExplanation status SUSPENDED"></div>
          <br />
          <div style={{display:"inline-block", verticalAlign:"middle"}}>FAILED</div>
          <div className="stateExplanation status FAILED"></div>
          <br />
        </div>

        <DependencyGraph job={this.state.job} dependencyProducerDepth={this.state.dependencyProducerDepth} dependencyConsumerDepth={this.state.dependencyConsumerDepth} />
      </TabPanel>
    </Tabs>
  </div>
</div>
    );
  }
});

