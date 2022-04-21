with GNAT.Sockets; use GNAT.Sockets;
with Ada.Containers.Vectors;
with Ada.Strings.Bounded;

package connection is
	package msg_str is new
		Ada.Strings.Bounded.Generic_Bounded_Length(Max=>1024);
	use msg_str;

	task type client_wrangler is
		entry start(sock: Socket_Type);
		entry send(msg: Bounded_String);
		entry recv(msg: out Bounded_String);
	end client_wrangler;

	type client is record
		wrangler: client_wrangler;
	end record;

	type client_ref is access client;

	package Connection_Vectors is new
	Ada.Containers.Vectors
		(Index_Type	=>	Natural,
		 Element_Type	=>	client_ref);
	use Connection_Vectors;

	connections: Vector;

	procedure new_connection(sock: Socket_Type);

	procedure send_message(msg: Bounded_String);
end connection;



