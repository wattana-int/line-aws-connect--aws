'use strict';
require('coffeescript/register');

let Router = require('./route');

exports.handler = async (event) => {
  let response = await Router.select(event);
  return response; 
}