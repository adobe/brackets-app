console.log('starting webserver in dir: ' + __dirname)

var connect = require('connect')
var WebSocketServer = require('ws').Server
var proxy = require('./proxy');

var app = connect()
.use(connect.static(__dirname + '/../../brackets/src/'))
.use(function(req, res){
    res.end('hello world\n');
})
.listen(3000);

var wss = new WebSocketServer({server: app});
wss.on('connection', proxy.handleConnection);

console.log('servers started, trying to redirect');
try {
    var cocoa = require('cocoa');
    console.log(cocoa.goToURL("http://localhost:3000"));
}
catch (e) {
    console.log("unable to redirect shell, maybe we aren't running in one");
}
