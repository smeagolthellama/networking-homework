with GNAT.Sockets; use GNAT.Sockets;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Bounded;
with Ada.Strings.Hash;

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
      sock: Socket_Type;
   end record;

   type client_ref is access client;

   package Connection_Maps is new
     Ada.Containers.Indefinite_Hashed_Maps
       (Key_Type	=>	String,
        Element_Type	=>	client_ref,
        Hash => Ada.Strings.Hash,
        Equivalent_Keys => "="
       );
   use Connection_Maps;

   connections: Map;

   procedure new_connection(sock: Socket_Type);

   procedure send_message(msg: Bounded_String);

   function Image (cli: client) return String;
end connection;



