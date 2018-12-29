# GridFw
GridFw is a fast, full, promise based and intuitive nodejs HTTP framework created by coredigix.com

## Route system
The router system use:
 1. Static routes: routes that do not contain any path param (fastest, can contain query parameters).
 2. Dynamic routes: For ultra speed, we use tree system and cache. @see our benchmarking 

Simple use:
```javascript
const GridFw = require('gridfw');

// create a new instance of our server
const app = new GridFw(); 

// link controller to this path
app.get('/static/path', function(ctx){});
app.get('/an/*other/sta**tic/path', function(ctx){});
// the last "star" must be escaped with "?", so it will not be considered as a wildcard param
app.get('/an/*other/sta**tic/?*path', function(ctx){});
// when a word after "/" starts with ":" or "?", it must be escaped with "?", so it will not be considered as a path param
app.get('/st::atic/?:path/??to/src', function(ctx){}); 

// use async function or return promise for asynchrone operations
app.get('/any/path', async function(ctx){});

// you can use parametred paths too (accessible via ctx.params.paramName)
app.get('/path/:param1/to/:param2', function(ctx){});

// or even wildcard params (will contain the rest of the path including slashes)
// wildcard param is accessible via: ctx.params['*']
app.get('/path/:myParam/*', function(ctx){});
// or named wildcard (accessible via: ctx.params.myWildcard)
app.get('path/to/*myWildcard', function(ctx){});
// wildcard must be in the end of the path declaration, otherwise will be considered as part of the url

// we support directly most used http methods
app.all('path', function(ctx){}); // link path to all http methods that are not explicitly linked
app.post('path', function(ctx){});
app.head('path', function(ctx){});
app.put('path', function(ctx){});
app.patch('path', function(ctx){});
app.delete('path', function(ctx){});
// tip: "GET" method is called when "HEAD" method isn't set. the framework take care of it.

// other http methods are supported via:
app.on('method-name', '/route', function(ctx){});

// to remove a controller:
// remove a handler from all http methods
app.off('all', '/route', handler);
app.off('get', '/route', handler);
app.off('post', '/route', handler);
app.off('any-http-method', '/route', handler);
// remove a route
app.off('all', '/route');
app.off('get', '/route');
app.off('post', '/route');
app.off('any-http-method', '/route');
// remove all routes on all methods
app.off('all');
app.off('get');
app.off('post');
app.off('any-http-method');
```
