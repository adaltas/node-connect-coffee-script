
// npm install connect
// node server.js
// curl http://localhost:3000/test.js

var coffeeScript = require('coffee-script');
var connectCoffeeScript = require('..');
var connect = require('connect');

var app = connect();

function compile(str, options) {
  options.bare = true;
  return coffeeScript.compile(str, options);
}

app.use(connectCoffeeScript({
  src: __dirname + '/view',
  dest: __dirname + '/public',
  compile: compile
}));

app.use(connect.static(__dirname + '/public'));

app.listen(3000)

console.log('http://localhost:3000/test.js');
