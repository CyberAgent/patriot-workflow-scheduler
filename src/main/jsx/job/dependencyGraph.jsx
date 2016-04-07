import React from 'react';
import JobClient from './common/jobClient';
import JobUtil from './common/jobUtil';
import ReactDOM from 'react-dom';

import d3 from 'd3';
import dagre from 'dagre';
import dagreD3 from 'dagre-d3';

import lodash from 'lodash';
import moment from 'moment';

module.exports = React.createClass({
  mixins: [JobUtil, JobClient],
  getDefaultProps: function() {
    return {
      rectHeight: 45
    };
  },
  getInitialState: function(){
    return {
      graphNodes: {},
      graphEdges: {},
    };
  },
  componentDidMount: function() {
    window.addEventListener('resize', this.handleResize);

    this.getGraph(
      this.props.job.job_id,
      this.props.dependencyProducerDepth,
      this.props.dependencyConsumerDepth,
      function(graph) {
        if (Object.keys(graph.nodes).length > 0) {
          this.setState({
            graphNodes: graph.nodes,
            graphEdges: graph.edges
          });
        }
      }.bind(this)
    );
  },
  componentWillReceiveProps: function(nextProps) {
    this.getGraph(
      nextProps.job.job_id,
      nextProps.dependencyProducerDepth,
      nextProps.dependencyConsumerDepth,
      function(graph) {
        this.setState({
          graphNodes: graph.nodes,
          graphEdges: graph.edges,
        });
      }.bind(this)
    );
  },
  componentWillMount: function(){
    this.redraw = lodash.debounce(this.redraw, 200);
  },
  componentWillUnmount: function() {
    window.removeEventListener('resize', this.handleResize);
  },
  redraw: function() {
    this.render();
  },
  handleResize: function(e) {
    this.redraw();
  },
  getHumanReadableTimeDiff: function(from, to) {
    // convert date to UTC format ISO 8601
    from  = moment.utc(moment(from).toISOString()).format();
    to    = moment.utc(moment(to).toISOString()).format();

    var diff = moment.duration(moment(from).diff(moment(to)));
    var days = parseInt(diff.asDays());
    var hours = parseInt(diff.asHours());
    hours = hours - days*24;
    var minutes = parseInt(diff.asMinutes());
    minutes = minutes - (days*24*60 + hours*60);
    var seconds = parseInt(diff.asSeconds());
    seconds = seconds - (days*24*60 + hours*60 + minutes*60);

    var humanReadableDiffString = '';
    if (days > 0) humanReadableDiffString += days + ' day(s)';
    if (diff.asHours() < 24*7 && hours > 0) humanReadableDiffString += hours + ' hour(s)';
    if (diff.asMinutes() < 60*24 && minutes > 0) humanReadableDiffString += minutes + ' minute(s)';
    if (diff.asSeconds() < 60*60 && seconds > 0) humanReadableDiffString += seconds + ' second(s)';

    return humanReadableDiffString;
  },
  render: function() {
    var nodes = this.state.graphNodes;
    var edges = this.state.graphEdges;

    if (typeof(window.d3) === "undefined") {
      // set a global variable because d3 >=3.4 no longer exports a global d3
      // https://github.com/mbostock/d3/issues/1727
      window.d3 = d3;
    }

    if (Object.keys(nodes).length > 0) {
      // changing dependency depth from 4 to 0 always re-produces this problem
      var g = new dagreD3.graphlib.Graph().setGraph({})
        .setDefaultEdgeLabel(function() { return {}; });
      g.graph().rankDir = "LR";

      // set nodes
      Object.keys(nodes).map(function(key, idx) {
        var node = nodes[key];
        var stateName = this.name_of_state(node.state);
        var jobTitle = node.job_id;

        // truncate if job_id is too long
        if (jobTitle.length > 142) {
          jobTitle = jobTitle.substr(0, 142) + "...";
        }

        var nodeSetting = {
          rx: 2,
          ry: 2,
          padding: 0,
          label: function() {
            var spanReactElement = document.createElement("span");
            var span = d3.select(spanReactElement);
            span.append("span").attr("class", "status " + stateName).html("&nbsp;");
            span.append("span").attr("class", "job_title").text(jobTitle);
            return spanReactElement;
          }
        };

        // highlight selfJob
        if (this.props.job.job_id === node.job_id) {
          nodeSetting['style'] = 'fill: #afeeee;';
        }
        g.setNode(key, nodeSetting);
      }.bind(this));

      // set edges: sort keys of edges to order nodes when rendering
      edges.sort().map(function(edge) {
        g.setEdge(edge[0], edge[1], { lineInterpolate: "basis" });
      }.bind(this));

      // set up an svg group so that we can translate the final graph.
      var svg = d3.select(this.refs.nodeTree);
      var inner = d3.select(this.refs.nodeTreeGroup);

      // set up zoom support
      var zoom = d3.behavior.zoom().on("zoom", function() {
        inner.attr("transform", "translate(" + d3.event.translate + ")" +
          "scale(" + d3.event.scale + ")");
      });
      svg.call(zoom);

      // create the renderer
      var render = new dagreD3.render();

      // run the renderer. this is what draws the final graph.
      render(inner, g);

      var divWidth  = this.refs.graphDiv.offsetWidth;
      var divHeight = innerHeight;

      var initialScaleHorizontal = divWidth / g.graph().width;
      var initialScaleVertical = divHeight / g.graph().height;

      var initialScale = initialScaleHorizontal < initialScaleVertical ? initialScaleHorizontal : initialScaleVertical;
      if (initialScale >= 1) initialScale = 1;

      // center and resize
      zoom
        .translate([(divWidth - g.graph().width * initialScale) / 2, 20])
        .scale(initialScale)
        .event(svg);
      svg.attr('height', divHeight);
      svg.attr('width', divWidth);

      // tooltip
      var tooltip = d3.select("body")
        .append("div")
        .attr("class", "jobToolTip")
        .style("position", "absolute")
        .style("visibility", "hidden");
      svg.selectAll("g.node").on("click", function(id) {
        if (d3.event.defaultPrevented) return;
        window.location = '/job/detail/' + encodeURIComponent(id);
      })
      .on("mouseover", function(id) {
        var job = nodes[id];

        var html = '';
        html += '<table class="jobTooltipTable">'
        html += '<tr><th>JOB ID</th><td>' + job.job_id + '</td></tr>';
        html += (job.exec_node !== null && job.exec_host != null) ? "<tr><th>node@host</th><td>" + job.exec_node + "@" + job.exec_host + "</td></tr>" : "";
        html += job.start_datetime !== null ? "<tr><th>start_datetime</th><td>" + job.start_datetime + "</td></tr>" : "";
        if (job.history !== null && job.history.begin_at !== null) {
          html += "<tr><th>BEGIN AT</th><td>" + job.history.begin_at + "</td></tr>";
        }
        if (job.history !== null && job.history.end_at !== null) {
          html += "<tr><th>END AT</th><td>" + job.history.end_at + "</td></tr>";
        }
        if (job.state === 2) { // RUNNING
          html += "<tr><th>EXECUTE ELAPSED TIME</th><td>" + this.getHumanReadableTimeDiff(new Date(), job.history.begin_at) + "</td></tr>";
        } else if (job.state === 0) { // SUCCEEDED
          html += "<tr><th>EXECUTE ELAPSED TIME</th><td>" + this.getHumanReadableTimeDiff(job.history.end_at, job.history.begin_at) + "</td></tr>";
          html += "<tr><th>TIME SINCE END TIME</th><td>" + this.getHumanReadableTimeDiff(new Date(), job.history.end_at) + "</td></tr>";
        }
        return tooltip
          .html(html)
          .style("visibility", "visible");
      }.bind(this))
      .on("mousemove", function(){
        if (d3.event.pageX > divWidth / 2 + 200) {
          return tooltip.style("top", (d3.event.pageY+10)+"px").style("left", (d3.event.pageX-300)+"px");
        } else {
          return tooltip.style("top", (d3.event.pageY+10)+"px").style("left", (d3.event.pageX+10)+"px");
        }
      }.bind(this))
      .on("mouseout", function(){
        // hide all tooltips at first
        d3.selectAll(".jobToolTip").style("visibility", "hidden");

        return tooltip.style("visibility", "hidden");
      });

      // set fixed height even if scaled to x %
      svg.selectAll("g.node rect").attr("height", this.props.rectHeight);
    }

    return (
      <div ref="graphDiv" className="nodeTree">
        <svg ref="nodeTree">
          <g ref="nodeTreeGroup"/>
        </svg>
      </div>
    );
  }
});

