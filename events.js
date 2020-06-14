TC3 = require("./index.js");
TC3.Events = {};
/**
TC3.Events[] = function(data){

};
*/

/** Client sends -- unknown
 * * evemts.lua:351
    400
    450
    610
*/
/** Client Recieves
    710 -- List of all known items {cmd:"710",items:[{type:,name:},{type:,name:,}...], numitems:488}
    730 -- List all known stations {cmd:"730",stations:[{id:number},{id:number}...], numitems:121}
    810 -- List all known ores {cmd:"810", ores"["Apicene","Aquean","Carbonic"...], numitems:15}
*/


TC3.Events[100] = function(data){
    //{cmd:"100", idstring:"opeaOAzep329dnroa882l3kweuwhsendw83gbsyaa", username:string, password:string}
    TC3.connected.push(data.username);
    TC3.send({ cmd:"500", users:TC3.connected.join(", "), useroptions:{navedit:0, memberedit:0}});//Login "OK";
    /**
        Client expected response:
        {cmd:"1000", version:string}
        {cmd:"1200"} --Update PloziNav lists.
        {cmd:"1500"} --Related to [Guild]/[GuildMembers] Server -> Member list

    */

    //TC3.send({ cmd:"501" }); //Login failed.
};


TC3.Events[101] = function(data){ //Client Logging out.
    //{cmd:"101"};
    /**
    sock.once("close", function() {
        console.log(`Connection to ${user} closed.`);
        TC3.send({ cmd:"503", username:user });
        //array.remove() FN get this user out array of "TC3.connected"
    });
     */
};


TC3.Events[700] = function(data){ //Load Sector Roid DB.
    //{cmd:"700",sectorid:number};
};


TC3.Events[1000] = function(data){ //Get Client Version, Send Server Version.
    //{cmd:"1000", version:string}
    let version=[server=TC3.Version, client=data.version];
    if(version.client != version.server){
        //TC3.Send()//Version out of date!!
    };
};


module.exports = TC3.Events;
