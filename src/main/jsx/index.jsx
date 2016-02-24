var React = require('react');
import { Router, Route, Link, IndexRoute, IndexRedirect } from 'react-router'

module.exports = React.createClass({
  render: function () {
    return (
      <div className="container">
        <Link to="/job"> Job Manager </Link>
      </div>
      );
  }
});

