# TCP-Server
My IP is using my Hamatchi IP.

• index.js == "Server"

•• Change IP to "127.0.0.1" for local host.


Client: Edit TC2/connections.lua:92 TCP.make_client(HOST, PORT,_,_,_)

|| "Host" = your server IP || "Port"=Server Port

This code uses "127.0.0.1"(LocalHost), and port "4444";

Note, Host may need to be changed to 127.0.0.1. (index.js)

node index.js to start server, change TC2/connections.lua:92 `TCP.make_client(vo.aoczone.net,27056,` to `TCP.make_client(127.0.0.1,4444,`
