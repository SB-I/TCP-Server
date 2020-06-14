const net = require("net");
let Events = require("./events.js");
TC3 = {
    host: "25.27.158.232",
    port: "4444",
    version: "",
    debug: 1,

    connected: [],
    Events: Events,
};

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

    TC3.send = function(data){
        d=JSON.stringify(data);
        if(TC3.debug) console.log(`Server Says: ${d}`);
        sock.write(d);
    };

    console.log(`Client connected: ${user}`);
    TC3.send({ cmd:"502", username:user })

    sock.on("data", function(d) { //d = data
        if(!d)return;
        console.log(`${user} says: ${d}`);
        let data = JSON.parse(d);
        //if(!data || data==null) return;

        try{
            TC3.Events[data.cmd](data);
        }catch(err){
            console.error(err);
        };
        /**
    //send({cmd:"", data})
    //init
        if(d.cmd==100){
            if(!users[sock.remoteAddress]){
                TC3.send({cmd:"501"})} //Login Failed. (IP/Name not saved.)
            }else{
                TC3.send({cmd:"500"}) //Login Successful.
            }
        if(d.cmd==1000){TC3.send({cmd:"1000", version:TC3.version});};
        //1200 -- NavData

        //900 -- "Get Ores"
        // * (recieves) {cmd:"900", sectorid:number}
        // * (expects) {cmd:"",objects:[{orename:"Not found"}],numitems:number}
        // * * (After - recieves) {cmd:"701", ???}
*/
    });


    sock.once("close", function() {
        console.log(`Connection to ${user} closed.`);
        TC3.send({ cmd:"503", username:user });
        //array.remove() FN get this user out array of "TC3.connected"
    });


    sock.on("error", function(err) {
        if(err == "Error: read ECONNRESET")return;
        if(err == "Error: This socket has been ended by the other party")return;
        console.log(`Connection error -> ${user} : ${err}`);
    });
});



server.listen(TC3.port, TC3.host, function() { //CreateServer.
    console.log(`Server listening on %j`, server.address());
      //"%j = json -> string"
});


module.exports = TC3;
