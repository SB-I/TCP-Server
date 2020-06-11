const net = require("net");
const host = "25.27.158.232";
const port = "1904";

const users = {
    "25.27.158.232":{username:"Scion Spy"},
    "25.77.132.39":{username:"Bejebajay"}
};


const server = net.createServer();

server.on("connection", function(sock) {
    var user = "";
    //const rAddr = `${sock.remoteAddress}:${sock.remotePort}`;
    if(!users[sock.remoteAddress]){
        console.log(`>> New login :: ${sock.remoteAddress}`);
        user = sock.remoteAddress;
    }else{
        user = users[sock.remoteAddress].username;
    };

    console.log(`Client connected: ${user}`);

    sock.on("data", function(d) { //d = data
        data = [];
        console.log(`${user} says: ${d}`);
        d = JSON.parse(d);
        console.log(`Cmd: ${d.cmd}`)
        if(!d)return;

        function s(txt){
            if(!txt) return
            console.log(`-> ${txt}`);
        };

        if(d.cmd==100){ s(100); sock.write("100")}
        if(d.cmd==101){s(101);sock.write("101");sock.end();};
        if(d.cmd==404){s(404);sock.write("404");};
    });


    sock.once("close", function() {
        console.log(`Connection to ${user} closed.`);
    });


    sock.on("error", function(err) {
        if(err == "Error: read ECONNRESET")return
        console.log(`Connection error -> ${user} : ${err}`);
    });
});



server.listen(port, host, function() { //CreatServer.
    console.log(`Server listening on %j`, server.address());
      //"%j = json -> string"
});
