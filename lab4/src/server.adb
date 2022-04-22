with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Sockets; use GNAT.Sockets;
with connection;

procedure server is
   socket: socket_Type;
   addr: Sock_Addr_Type;
Begin
   Create_Socket(socket);
   addr.Addr:=Any_Inet_addr;
   addr.Port:=7777;
   Bind_Socket(socket,addr);
   Listen_Socket(socket);
   loop
      declare
         new_sock: socket_Type;
         new_addr: Sock_Addr_Type;
      begin
         Put_Line("waiting for new connections.");
         Accept_Socket(socket,new_sock,new_addr);
         Put_Line("new connection from "& Image(new_addr));
         Put_Line("Connecting client...");
         connection.new_connection(new_sock,Image(new_addr));
         Put_Line("Sending arrival notice to all conencted clients.");
         connection.send_message(connection.msg_str.To_Bounded_String(Image(new_addr) &" joined."));
         Put_Line("Sent!");
      end;
   end loop;
end server;

