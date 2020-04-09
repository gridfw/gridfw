# GridFw
Gridfw is a super-fast, promise based and intuitive nodejs http framework created by coredigix.com
The need behind Gridfw is to have a rebuts, fault tolerant and simple http framework to serve as a web server or Rest API

## Install
Get in your project folder and install Gridfw as follow (command line):
```
npm install gridfw --save
```

## Hello world example

Create a javascript file "app.js" with the following content
```javascript
const Gridfw = require('gridfw');

// create basic application with default options
const app= new Gridfw();

// add root page
app.get('/', function(ctx){
	ctx.send('Hello world');
});

// Start server listening on localhost
app.listen(3000).then(function(){
	app.info('APP', 'Server is running on localhost:' + app.port);
}).catch(function(err){
	app.fatalError('APP', 'Server Start failed: ', err);
});
```

Now run your app from command line
```
node app.js
```

## Create application
```javascript
const Gridfw = require('gridfw');

// create basic application with default options
const app= new Gridfw();

// create app using external config file
const app= new Gridfw('/path/to/config-file[.json, .js]');

// create application and set configuration
const app= new Gridfw({params});
```
>To enable production mode, set param `isProd: true` in your configuration file or init params. @see application advanced config bellow.

## Start listening
```javascript
// Start listening on configured port or on an arbitrary available port
// Throws error if the port isnt available
<promise> app.listen()

// Set a specific port
<promise> app.listen(3000)

// or
<promise> app.listenn({
	port: 3000,
	protocol: 'http'
})
```


## Route system
The router In Gridfw uses a tree-based algorithm and cache to reduce significantly the routing overhead
The router system uses:
 1. Static routes: routes that do not contain any path param (fastest, can contain query parameters).
 2. Dynamic routes: For ultra speed, we use tree system and cache. @see our benchmarking 

### Assign controller to a path
A typical URL contains 5 main parts (and other optional parts like password and username that we will not discus here)
1-	Protocol: like “http:”, “https:”, “ftp:”, …
2-	Host: The website host,  like: example.com
3-	Path: or pathname, it’s the path of the resource inside the website
4-	Search params: Anything in the path after “?” and before “#”, it contains query params (accessible in gridfw via `ctx.query.paramName`)
5-	Hash: Anything after “#” it is not sent to the server, so it’s accessible for local javascript (in the browser) only

In routing, we map each PATH of the URI to a specific logic (function or series of functions). We ignore other parts.
In Gridfw, each pair of path and HTTP Method is mapped to a single controller (the function that has the execution logic) so we prevent any issue caused with multiple execution logics.


```javascript
// use "on" method to assign a controller to a path
app.on('HTTP_METHOD', '/', function(ctx){ LOGIC });	// Root path
app.on('HTTP_METHOD', '/path', function(ctx){ LOGIC });
app.on('HTTP_METHOD', '/path2', async function(ctx){ LOGIC });
app.on('HTTP_METHOD', '/path3', function(ctx){ return new Promise() });

// You can use those methods directly without "on"
app.get('/path', function(ctx){ LOGIC });
app.head('/path', function(ctx){ LOGIC });
app.post('/path', function(ctx){ LOGIC });
app.put('/path', function(ctx){ LOGIC });
app.patch('/path', function(ctx){ LOGIC });
app.delete('/path', function(ctx){ LOGIC });

// Assign controller to all HTTP_METHODS
app.all('/path', function(ctx){});
app.on('all', '/path', function(ctx){});

// Assign multiple routes
app.get(['/path', '/path2'], function(ctx){ LOGIC });
app.on('GET', ['/path', '/path2'], function(ctx){ LOGIC });

// Assign multiple methods
app.on(['GET', 'POST'], '/path', function(ctx){ LOGIC })
app.on(['GET', 'POST'], ['/path', '/path2'], function(ctx){ LOGIC })

```

>***TIP:*** If “Head” method isn’t present on a path, the framework will use the “GET” method and ignore data sending (sends only headers as the “head” method is supposed to do).

### Remove a controller from a path
```javascript
// remove a controller/handler
app.off('all', '/route', handler);
app.off('get', '/route', handler);
app.off('post', '/route', handler);
app.off('any-http-method', '/route', handler);

// remove the route
app.off('all', '/route');
app.off('get', '/route');
app.off('any-http-method', '/route');

// remove all routes on all methods
app.off('all');
app.off('get');
app.off('post');
app.off('any-http-method');
```

### Static paths
```javascript
app.on('/static/path', function(ctx){});
app.get('/an/*other/sta**tic/path', function(ctx){});

// the last "star" must be escaped with "?", so it will not be considered as a wildcard param
app.get('/an/*other/sta**tic/?*path', function(ctx){});

// when a word after "/" starts with ":" or "?", it must be escaped with "?",
// so it will not be considered as a path param
app.get('/st::atic/?:path/??to/src', function(ctx){}); 
```

### Dynamic paths
Dynamic paths could use parameters and wildcards
You can access parameters via `ctx.params.paramName`
You can access wildcard parameters via `ctx.params['*paramName']`

```javascript
// Based on parameters
app.get('/path/:param1/to/:param2', function(ctx){
	console.log('param1>> ', ctx.params.param1);
	console.log('param2>> ', ctx.params.param2);
});

// A wildcard param will contain the rest of the path including slashes
app.get('/path/to/*', function(ctx){
	console.log('Rest of the path>> ', ctx.params['*']);
});
app.get('/path/to/*param', function(ctx){
	console.log('Rest of the path>> ', ctx.params['*param']);
});

// You can combine wildcard and other params
app.get('/path/to/:myParam/and/*', function(ctx){
	console.log('myParam>> ', ctx.params.myParam);
	console.log('Rest of the path>> ', ctx.params['*']);
});
```

### Preprocessing params
**Use case:**
We send a param called “user” to our app (As path param or as a query param). This params contains a use Id.
We need in our controllers to use this user Object (load data from database and init user object)
To make this process fast, and reduce the code, use the following:
```javascript
// add user param
app.param({
	// @Required: set a name for your param
	name: 'user',	// param name: required
	// @Optional @Recommanded: add a matcher
	matches: /^\d{5}$/,		// as regex
	matches: function(value){return true},	// or as function
	// @Optional: Add a resolver
	resolver: async function(value){
		userData= await DB.users.findById(value);
		user= new User(userData);
		return user
	}
})
```

Now you will be able to use it in your controllers
```javascript
// user calls:	/users/1234/endpoint
app.get('/users/:user/endpoint', function(ctx){
	console.log('USER: ', ctx.params.user);
	// This will print resolved "user" object instead of the original user id (1234)
});

// user calls: /my/bla/bla?user=1234
app.post('/my/bla/bla', function(ctx){
	console.log('USER: ', ctx.query.user);
	// This will print resolved "user" object instead of the original user id (1234)
})
```

## Serving static files
Serving static files is simple as:
```javascript
app.get('/public/*', (ctx)=> ctx.sendFile('/root-dir/' + ctx.params['*']) );

// or better using path library
app.get('/public/*', (ctx)=> ctx.sendFile( Path.join('/root-dir', ctx.params['*']) ) );

// you can set params to ctx.sendFile @see documentation bellow
app.get('/public/*', function(ctx){
	return ctx.sendFile(Path.join('/root-dir', ctx.params['*']), {maxAge: '7d'});
});

// You can use "GridFW.static" too as follow
app.get('/public/*', GridFW.static('/root-dir') )
app.get('/public/*', GridFW.static('/root-dir', {options}) )

// You can use "ctx.download" to trigger download manager on client side instead of showing the file in the browser
app.get('/downloads/*', (ctx)=> ctx.download( Path.join('/root-dir', ctx.params['*']) ) );
```

ctx.sendFile will return a promise, it's important to return this promise or waiting for it. otherwise, the request will be terminated before the file is sent.

Possible options for ctx.sendFile and ctx.download are:
```javascript
{
	maxAge: '7d' 		// use browser cache for 7 days to serve future calls to this file
	// maxAge: '2 days'
	// maxAge: '10h'	// 10 hours
	// maxAge: '5s'		// 5 seconds (seriously! hhhhh)
	// maxAge: '10m'	// 10 minutes
	// maxAge: 30000	// 30 seconds

	root:			'/root/dir'	// Root directory for relative filenames.
	lastModified:	true		// When false, disable the "lastModified" header. @default true
	headers:		{headers}	// send custom http headers with the file
	acceptRanges:	true		// Enable or disable accepting ranged requests. @default true
	cacheControl:	true		// Enable or disable setting Cache-Control response header. @default true
	immutable:		false		// Enable or disable the immutable directive in the Cache-Control response header. If enabled, the maxAge option should also be specified to enable caching. The immutable directive will prevent supported clients from making conditional requests during the life of the maxAge option to check if the file has changed. @default false
}
```

>***TIP:*** In production mode, use proxies like Nginx or Apache to cache static files. This will reduce charge on your server.

## Serving JSON
Creating your json API is simple as:
```javascript
app.get('/path/to/my/api', function(ctx){
	// ... Your logic
	return ctx.json({data});
	// or: await ctx.json({data});
	// <!> it's important to wait for the json sent by using "await" or returning the ctx.json promise
});

app.get('/path/to/my/api?cb=myFx', function(ctx){
	// ... Your logic
	return ctx.json({data});
	// or: await ctx.json({data});
	// <!> it's important to wait for the json sent by using "await" or returning the ctx.json promise
});
```
>In developpement mode, Gridfw will render pretty JSON and JSONP and HTML. In production mode they will be minified.
>To change this behaviour, use "pretty" param (@see advanced configuration bellow).

## Serving JSONP
Creating your jsonp API is simple as:
```javascript
app.get('/path/to/my/api', function(ctx){
	// ... Your logic
	return ctx.jsonp({data});  // will send: "callback({data})"
	// or: await ctx.jsonp({data});
	// <!> it's important to wait for the jsonp sent by using "await" or returning the ctx.jsonp promise
});

app.get('/path/to/my/api?callback=myFx', function(ctx){
	// ... Your logic
	await ctx.jsonp({data});	// will send: "myFx({data})"
});
```
>To change "callback" query param name of the default function name, see app configuration bellow.

## Context variable

### Current app
To access current app from context, use: `ctx.app`

### Native request and response
To access native request and response objects, use: `ctx.req` for request and `ctx.res` for response.

### ctx.send
Send data to the client and close the request.
Its sigature is: `<promise> ctx.send(<data>)`
The data could be String, buffer, Number or Object (will be serialized as JSON)

### HTTP status: ctx.statusCode, ctx.statusText
```javascript
ctx.statusCode= 200;
ctx.statusMessage= "done";
```

### Set response content-type, encoding and content-length
It’s recommended to let the framework manage those flags for you.
```javascript
ctx.type('Mime-Type');
ctx.type('application/json');	// inform the client that this is a json

// OR
ctx.contentType= 'application/json'	// set the content type
ctx.encoding= 'utf8'		// set text encoding, @Default UTF8
ctx.contentLength= Number	// set content length
```

### Send redirects
```javascript
<promise> ctx.redirect(URL or String);			// Send Temporary redirect
<promise> ctx.redirectPermanent(URL or String);	// Send permanent redirect
<promise> ctx.redirectBack();	// Redirect to previous URI if inside the website, to home otherwise
```

Example of use
```javascript
app.get('/myPath', function(ctx){
	// ... Logic
	await ctx.redirect('/my-new-path');
});

//or
app.get('/myPath', function(ctx){
	// ... Logic
	return ctx.redirect('/my-new-path');
});
```

### Manage request headers

#### Get header
```javascript
headers= ctx.reqHeaders	// Get all request headers
headers= ctx.req.headers	// alias

myHeader= ctx.reqHeaders['my-header']	// get a single header
hasHeader= ctx.req.hasHeader('header-name')	// check header present

```

#### Select user prefered language from a list of languages
```javascript
// If the browser supports "webp", this will return "image/webp"
// If all arguments are missing or no "accept" header, undefined will be returned
var selectedValue= ctx.accept('image/webp', 'image/png', 'image/*');
// or
var selectedValue= ctx.accept(['image/webp', 'image/png', 'image/*']);
```

#### Select the most relevant language of a client
When a browser sends a request, it sends a header to tell the server about languages that the user uses and his ordering preference.
To detect this language, use the following: (ordering has no impact)

```javascript
var userLang= ctx.acceptsLanguages('en-US', 'en', 'fr', 'es');
// or
var userLang= ctx.acceptsLanguages(['en-US', 'en', 'fr', 'es']);
// it will returns "undefined" if no language is selected
```

#### Select encoding and charset
use `ctx.acceptsEncodings` and `ctx.acceptsCharsets` like previous.

### Manage response header

```javascript
// add header 
ctx.addHeader('header-name', 'header value');

// remove all headers with name "header-name" and add an new one
ctx.setHeader('header-name', 'header value');

// get all headers with name "header-name"
headers= ctx.getHeader('header-name');

// check if a header is present
hasHeader= ctx.hasHeader('header-name');

// remove a header
ctx.removeHeader('header-name');
```

### Write chanks (advanced use)
```javascript
<promise> ctx.write(chunk);
<promise> ctx.write(chunk, 'encoding');
```

### Request status
```javascript
var isAborted= ctx.aborted		// if the client aborts the request
var isFinished= ctx.finished	// if the request is finished and close
var doesHeadersSent= ctx.headersSent	// if headers are sent (data sending started)
```

### Set request timeout
```javascript
ctx.setTimeout(Number);
ctx.setTimeout(Number, cb); // cb is a callBack when timedout
```

### Detect Request URL and flags
```javascript
var httpVersion=	ctx.httpVersion	// HTTP version used by the client (over trusted proxies)
var method=			ctx.method		// used method: GET, POST, ...
var protocol=		ctx.protocol	// used protocol: HTTP, HTTPs, HTTP2 (over trusted proxies)
var secure=			ctx.secure		// if the request (over trusted proxies) used encrypted connection (HTTPs or http2)
var ip=				ctx.ip			// client IP (over trusted proxies)
var hostname=		ctx.hostname	// (over trusted proxies)
var fresh=			ctx.fresh		// if the request is fresh
var xhr=			ctx.xhr			// if the request is via Ajax

var url=			ctx.url			// Get original full URL
var path=			ctx.path		// get relative path excluding from app base path (if app isn't mounted on '/')
```

## Render
*** TODO ***

## Cookies
It’s recommended to store data in sessions, use cookies only to store very small information like session key.
```javascript
// get cookies
myCookie= ctx.cookies.cookieName

// set cookie
ctx.cookie('cookie-name', 'cookie-value');
ctx.cookie('cookie-name', 'cookie-value', {options});

// remove cookie
ctx.clearCookie('cookie-name');

// supported options are:
options= {
	domain: String, // Domain name for the cookie. Defaults to the domain name of the app.
	expires: Date, // Expiry date of the cookie in GMT. If not specified or set to 0, creates a session cookie.
	httpOnly: Boolean, // Flags the cookie to be accessible only by the web server.
	maxAge: Number, // Convenient option for setting the expiry time relative to the current time in milliseconds.
	path: String, // Path for the cookie. Defaults to “/”.
	secure: Boolean, // Marks the cookie to be used with HTTPS only.
	sameSite: Boolean // @See https://tools.ietf.org/html/draft-ietf-httpbis-cookie-same-site-00#section-4.1.1
};
```
To encrypt cookie value, see application advanced configuration bellow.

## Upload Data
Supported data formats are:
- Form urlencoded
- Multipart/data
- application/JSON

Any other format will be uploaded as a file.
```javascript
// upload data from the client using default options
<Promise(data)> ctx.upload();

// Accept only specific Mime-Type
<Promise(data)> ctx.upload({
	type: 'application/x-www-form-urlencoded'	// Expected form encodded only
	type: 'multipart/form-data'		// Expected multipart data only
	type: 'application/json'		// Expected JSON only
	type: 'Mime-Type'				// Accept only that mimetype
	type: ['M1', 'M2']				// Set a list of accepted mimetypes
});

// General format
try{
	uploadedData= await ctx.upload({
		type: 'mime/type',
		timeout: 3000,	// Uploading timeout (has no effect if you run app behind a local proxy because the proxy uploads the data before sending it at once to the app)
		limits: {
			/**
			 * Full request max size
			 * @default 20M
			 */
			size: 20 * (2**20)
			/**
			 * field name max size in bytes
			 * @default 1000
			 */
			fieldNameSize: 1000
			/**
			 * Field max size in bytes
			 * @default 1M
			 */
			fieldSize: 2**20
			/**
			 * Max non file fields count
			 * @default 1000
			 */
			fields: 1000
			/**
			 * Each file max size in bytes
			 * @default 10M
			 */
			fileSize: 10 * (2**20)
			/**
			 * Max files count
			 * @default 100
			 */
			files: 100
			/**
			 * Max fields count (files + non files)
			 * @default 1000
			 */
			parts: 1000
			/**
			 * Max number of header of each part
			 * @default 2000
			 */
			headerPairs: 2000
		},
		/**
		 * Files when multipart/data
		 */
		files: {
			fields: ['images'] // List of accepted fields to be files
			extensions: ['.jpg', '.jpeg', '.png', '.webp', '.tiff', '.gif', '.svg'] // Accepted file extensions (prefixed with ".")
			keepExtension: true	// keep extensions when saving as tmp file, this will help to do operation on the tmp file like image crop
		}
	});

	// Multipart/data file fields will contains the following
	file: {
		path:	'/path/to/tmp-file',
		name:	'file-name',
		size:	Number, // file size in bytes
	}
	// For formats that consedired as files, the response will contains the same as a multipart file 
}finally{
	// if it's a multipart data, remove tmp files
	await uploadedData.removeTmpFiles();
}
```

## SESSION management
Gridfw flexibility enables you to create your own session management without a heavy framework.
Just use wrappers as following: 
```javascript
app.wrap('/*', function(ctx, next){
	// your session logic
		// Get your session key from the cookies or Query token or what ever
		var sessionId= ctx.cookies.sessionId // or ctx.query.token for tokens
		// Get session if id found
		if(sessionId) {
			// load session from your database like MongoDB or Redis (or use in memory cache, but not recommaded for big projects)
			var session= await LoadAndRefreshSessionLogic(sessionId);
		}
		// create session if not found
		if(!session)
			// create new session descriptor in your database
			session= await createNewSessionLogic();
			ctx.cookie('sessionId', session.id);
	// add session to context
	ctx.session= session
	// if you store user prefered language in the session, it's time to load it
	ctx.setLanguage(session.language);
	// return "next" promise
	return next();
});
```
We suggest the following behavior for the session
```javascript
// load most accessible values directly to the session object
ctx.session.username

// Heavy values could be loaded on demande using method like
myHeavyValue= await ctx.session.get('key');

// to set a value, you will need a solution like:
ctx.session.set('key', 'value');
// or
ctx.session.set({key:value});
```



## Middlewares and wrappers

### Global wrapper (before do routing)
This will be called before routing request. It helps to do some rewrites and changes.
```javascript
app.wrap(function(ctx, next){
	// preprocessing
	await next(); // execute logic including routing, controllers, ...
	// post processing
});
```
Example:
We need to use paths like: /{language}/my/path. This to improuve pages SEO.
But it's not pretty to add a language param to all routes.
Ideally, we want to use routes like "/my/path" instead of "/:lang/my/path"

To Do this, do the following (Simple code for understanding, you can optimize it)
```javascript
app.wrap(function(ctx, next){
	pathParts= ctx.path.split('/');
	// Set context language
	ctx.setLanguage( pathParts.shift() );
	// change the context path to remove language from it
	ctx.path= pathParts.join('/');
	// await for "next" logic or return it's promise
	return next()
});
```

### Route wrapper
Route wrappers run after routing done and just before and after the controllers. It runs only if a controller is selected (path found) and has full access to context (resolved params, …)
```javascript
app.wrap('/route', function(ctx, next){
	// preprocessing
	resp= await next(); // execute logic including routing, controllers, ...
	// post processing
	return resp;
});
// It is recommanded to return "next" response. Oterwise controllers like "=>'/path/to/view'" and "=> {data}" will not work
```
Example of use: Session management, Analytics, ...


## Application

### flags
```javascript
// check if app is listening
<Boolean> app.listening
// get app version (set in config file)
<String> app.version

// if the app is enabled
<Boolean> app.enabled

// Disable the app: Stop any future user calls
<Promise> app.disable()
// Renable the app
<Promise> app.enable()

// Waiting for the app to start
await app.starting()

// reload the app
<Promise> app.reload()			// with previous configuration file
<Promise> app.reload({config})	// with specified configuration
<Promise> app.reload('/path/to/new/config/file')	// with new config file
```

## Error handling

### Handle specific route and subroutes errors
```javascript
app.catch('/route', function(ctx, err){
	// logic
})
```

### Handle Global Errors
#### In the code
Use the code to change error handlers dynamically. For most use cases, it’s not recommended.
```javascript
app.errors[ErrorCode]= async function(ctx, errCode, err){};	// call this when this error happend
app.errors.else= async function(ctx, errCode, err){};	// call this for unknown errors

// EXAMPLE
app.errors[404]= => 'errors/404'	// render 404 page
app.errors.['404-file']= => 'errors/404-file'	// render 404 page, file not found
```

#### In your configuration file (if it's a JS file)
@see configuration file bellow.


## LOG management
It’s recommended to use logging inside your app.


### Global logging
This will save additional information about your current app status
```javascript
app.debug('string-descriptor', ...args);
app.log('string-descriptor', ...args);
app.info('string-descriptor', ...args);
app.warn('string-descriptor', ...args);
app.error('string-descriptor', ...args);
app.fatalError('string-descriptor', ...args);	// should send email to admin about the error immediatly
```

### Logging inside a request context
This will save additional information about the request context like URL, user, session, ...
```javascript
ctx.debug('string-descriptor', ...args);
ctx.log('string-descriptor', ...args);
ctx.info('string-descriptor', ...args);
ctx.warn('string-descriptor', ...args);
ctx.error('string-descriptor', ...args);
ctx.fatalError('string-descriptor', ...args);
```

### Get/Set the log level
```javascript
// Get logLevel
var logLevel= app.logLevel

// set logLevel to warn
// This means "LOG" and "DEBUG" and "INFO" will be ignored
app.logLevel= 'warn'

//  or set LogLevel inside your config file
logLevel: 'warn'
```

### Create your custom log
```javascript
app.addProperties({
	// Add to app
	App:{
		debug: function(){ LOGIC },
		//...
	},
	// Add to context
	Context:{
		debug: function(){ LOGIC },
		//...
	}
});
```


## Addvanced app configuration
The framework will use default values for unset params.

### Select configuration
```javascript
// The app will load configuration from "./gridfw-config.js" or "./gridfw-config.json" if found
app= new Gridfw();

// Set custom configucation file (JS or JSON)
app= new Gridfw('/path/to/configucation-file');

// Set directly the configuration on the code
app= new Gridfw({configuration});
```

### Available params

```javascript
{
	isProd:		Boolean,	// Enable/disable production mode
	logLevel:	'debug',		// Log level: [debug, log, info, warn, error, fatalError]

	// APP INFORMATION
	name:		String,		// Your app name
	author:		String,		// Author
	email:		String,		// Admin email
	settings:	{},			// Your custom settings, we recommand to use "Gridfw-compiler" logic instead

	// APP CONFIG
	port:		String,		// listening port, @default 0. 0 means to select an available port
	protocol:	String,		// protocol to use, could be HTTP, HTTPS or HTTP2. If you use a local proxy like Nginx or Apache, we recommand to use "HTTP" and use "HTTP2" in the proxy
	baseURL:	String,		// If you use a proxy, This will help the app to know its real URL

	// PROXY
	/**
	 * This will help to correct "ctx.ip", "ctx.host" and other client iformation
	 * With default configation, if the app is behind a local proxy, ctx.ip will be always the proxy IP ("127.0.0.1" if on same machine) and ctx.host to poxy host (like "localhost")
	 * Returning always "true" will open your app to several security vulnerabilities
	 * Typically, in production mode, your app will be behind one proxy. So set this to "function(ctx, level){return level < 1}" to get correct client API and HOST
	 */
	trustProxy:	function(ctx, level){return level < 1},	// trust only local proxy

	// ROUTING
	/**
	 * Ingnore or not the trailing slash
	 * Means do those two paths "/example/" and "/example" are the same or not
	 * Possible values:
	 * 		- false:	Just ignore the trailing slash
	 * 		- 0:		Redirect to path without trailing slash. Ie: permanent redirect "/example/" to "/example"
	 * 		- true:		The two paths are different, Ie: "/example" and "/example/" are two different paths
	 * @default 0
	 */
	trailingSlash: 0,
	
	/**
	 * Do ignore path char case
	 * Possible values are:
	 * 		- 1:		Ignore case: "/example", "/Example", "/EXAMPLE" are all the same path
	 * 		- true:		Ignore case for the static part of the url. Selected parts with params will keept as it is @see path params above.
	 * 		- false:	Do not ignore char case: "/example", "/Example", "/EXAMPLE" are different paths
	 */
	routeIgnoreCase: Boolean,
	// PLUGINS
	enableDefaultPlugins: true,	// Enable Gridfw default plugins

	// ERROR HANDLING
	errors:{
		// Handle error with specific code
		ERROR_CODE:	async function(ctx, errCode, err){ LOGIC },
		// default error handler
		else: async function(ctx, errCode, err){ LOGIC },

		// Examples
		404: (ctx)=> ctx.status(404).send('page not found')
		'404-file': (ctx)=> ctx.status(404).send('File not found')
		else: (ctx)=> ctx.status(500).send('Internal server error')
	},
	
	// PLUGINS
	plugins: {
		PLUGIN_NAME: {
			require:	'plugin-require',
			...options
		},
		// # values
		// cookie manager
		cookie: {
			require: 'gridfw-cookie',
			secret: 'gw'	// @optional secret to ecrypt cookie value
		},
		// i18n
		i18n: {
			require: 'gridfw-i18n'
			/**
			 * Mapper path, @see Gridfw-i18n for more information
			 */
			mapper: './i18n/mapper.js'
		},
		// View render
		render: {
			require: 'gridfw-render',
			/**
			 * Path to views folder
			 * @default ./views
			 */
			views: './views'
		},
		// # downloader (sending files to client)
		downloader: {
			require: 'gridfw-downloader',
			etag:	true,	// add etag http header
			pretty:	true,	// show JSON, JSONP, XML and HTML in pretty format
			jsonp:	function(ctx){return ctx.query.cb || 'callback'}	// Resolve jsonp callback name
		},
		// # uploader
		uploader: {
			require: 'gridfw-uploader',
			/**
			 * Upload default timeout
			 * @default 10m
			 */
			timeout: 10 * 60 * 1000
			/**
			 * Upload temporary directory
			 * @default OS tmp dir
			 */
			tmpDir: require('os').tmpdir()
			/**
			 * Multipart data limits
			 */
			limits: {
				/**
				 * Full request max size
				 * @default 20M
				 */
				size: 20 * (2**20)
				/**
				 * field name max size in bytes
				 * @default 1000
				 */
				fieldNameSize: 1000
				/**
				 * Field max size in bytes
				 * @default 1M
				 */
				fieldSize: 2**20
				/**
				 * Max non file fields count
				 * @default 1000
				 */
				fields: 1000
				/**
				 * Each file max size in bytes
				 * @default 10M
				 */
				fileSize: 10 * (2**20)
				/**
				 * Max files count
				 * @default 100
				 */
				files: 100
				/**
				 * Max fields count (files + non files)
				 * @default 1000
				 */
				parts: 1000
				/**
				 * Max number of header of each part
				 * @default 2000
				 */
				headerPairs: 2000
			}
		}
	},

	// CACHE
	/**
	 * In production mode, the frameword will load used views, i18n and other resources to memory to make response faster.
	 * Idle resources will be removed from memory
	 * Setting this to "0" will disable the cache, and so the framework will load views, i18n and other needed resources on each request (Useful for dev mode)
	 * We recommand to not change those params
	 * @default 10M in production mode, 0 in dev mode
	 */
	jsCacheMaxSize:	10 * 2**20,	// 10M: max size of the cache
	jsCacheMaxSteps: 500,	// keep as it is
}
```

## Mount a sub application
Some times you need to isolate an application inside a root, but keep access to parent application (for session, config, ..)
To do this, use the following:
```javascript
app.all('/sub-app/root/route', subApp);
```


## Create Plugins
To add or remove properties from Gridfw, use the following methods
```javascript
// Add properties
app.addProperties({
	// Add to app
	App: {
		property: value,
		property2: function(args){
			this		// Current app
		}
	},
	// Add to Context
	Context: {
		property: value,
		property2: function(args){
			this		// Current context
			this.app	// Current app
		}
	}
});

// Remove properties
app.removeProperties({
	App: {
		property: value	// remove this property if has this value
	},
	Context: {
		property: value	// remove this property if has this value
	}
});
```

>We change how Gridfw plugins are made to make them easier. For the moment you need to do it with “addProperties” only.


# Supporters
[![coredigix](https://www.coredigix.com/img/logo.png)](https://coredigix.com)



```javascript
```