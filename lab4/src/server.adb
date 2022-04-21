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
			Accept_Socket(socket,new_sock,new_addr);
			connection.new_connection(new_sock);
         connection.send_message(connection.msg_str.To_Bounded_String("new person joined from "& Image(new_addr) &"."));
		end;
	end loop;
end server;

