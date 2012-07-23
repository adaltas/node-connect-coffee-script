# connect-coffee-script

It provide a simple [connect] middleware to serve CoffeeScript files. It is modeled after the [Stylus] middleware.

This project was created after the drop of native support for CoffeeScript in latest Express. More specifically, [Express] droped the compiler middleware in its versions 2 and 3 (the current versions at the time of this writing).

# Example


```javascript
var coffeescript = require('connect-coffee-script');
var connect = require('connect');

var app = connect();

app.use(coffeescript({
    src: __dirname,
    dest: __dirname + '/public',
    bare: true
}));

app.use(connect.static(__dirname + '/public'));

app.listen(3000)
```

[connect]: http://...
[stylus]: http://...
[express]: http://...
