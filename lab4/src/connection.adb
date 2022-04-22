with Ada.Strings; use Ada.Strings;
with Ada.Text_IO; use Ada.Text_IO;

package body connection is
   
   
   task body client_wrangler
   is
      socket: Socket_Type;
      
      protected type data is
         procedure set(str: Bounded_String) ;
         entry get(str: out Bounded_String) ;
      private
         private_str: Bounded_String;
         is_set: Boolean:=False;
      end data;
      
      protected body data is
         procedure set(str: Bounded_String) is
         begin
            if is_set then
               is_set:=False;
               Append(private_str, Character'Val(0) & str, Right);
               is_set:=True;
            else
               private_str:=str;
               is_set:=True;
            end if;
            put_line("string set to " & To_String(str));
         end set;
         entry get(str: out Bounded_String) 
           when is_set is
         begin
            str:=private_str;
            is_set:=False;
         end get;
      end data;
      
      send_msg, recv_msg: data;
      
      name: Bounded_String:=To_Bounded_String("anonymous chatter");
      
      task communicate
      is
         entry comm_start(sock: Socket_Type);
         entry send_message;
      end communicate;
      
      
      task body communicate
      is
         c_socket: Socket_Type;
         data_stream: Stream_Access;
         selector: Selector_Type;
         r, w: Socket_Set_Type;
         status: Selector_Status;
         message: Bounded_String;
      begin
         Put_Line("communicate task spawned. waiting to start.");
         accept comm_start(sock: Socket_Type) do
            c_socket:=sock;
         end comm_start;
         Put_Line("Got socket. Starting.");
         Create_Selector(selector);
         data_stream:=Stream(c_socket);
         loop
            select
               accept send_message do
                  Put_Line("got send_message entry. getting message.");
                  send_msg.get(message);
                  Put_Line("Message '" &To_String(message)&"' got.");
                  Empty(r);
                  Empty(w);
                  Set(w,c_socket);
                  Put_Line("Checking if socket is ready to be written to.");
                  Check_Selector(selector,r,w,status,1.0);
                  Put_Line("Check_Selector finished.");
                  if Is_Set(w, c_socket) and status=Completed then
                     Put_Line("Socket is ready to be written to. Writing message.");
                     String'Output(data_stream,To_String(message));
                     Put_Line("sent message.");
                  else
                     send_msg.set(message);
                     requeue send_message;
                  end if;
               end send_message;
            else
               delay 0.01;
               Empty(r);
               Empty(w);
               Set(r,c_socket);
               Put_Line("Checking if socket has readable data.");
               Check_Selector(selector,r,w,status,0.1);
               Put_Line("Check_Selector finished");
               if Is_Set(r, c_socket) and status=Completed then
                  Put_Line("Socket has readable data. Reading.");
                  -- can read from c_socket
                  declare
                     S: constant String:=String'Input(data_stream); 
                  begin
                     Put_Line("Read '"&S&"'.");
                     message:=To_Bounded_String(S);
                  end;
                  Put_Line("Attempting to send the message to everyone.");
                  send_message(message);
                  Put_Line("Sent message.");
               end if;
            end select;
         end loop;
      end communicate;
      
   begin
      Put_Line("client_wrangler task spawned. waiting to start.");
      accept start(sock: Socket_Type) do
         client_wrangler.socket:=sock;
      end start;
      Put_Line("Got socket. starting communicate task.");
      communicate.comm_start(socket);
      loop
         select
            accept send(msg: Bounded_String) do
               Put_Line("client_wrangler with socket " & Image(Socket => socket) &
                          " got entry send('" & To_String(msg) &"'). Setting send_msg.");
               send_msg.set(msg);
            end;
            Put_Line("client_wrangler with socket " & Image(Socket => socket) &
                       " dispatching send_message entry to communicate task.");
            communicate.send_message;           
         or
            accept recv(msg: out Bounded_String) do
               select
                  delay 0.01;
                  msg:=Null_Bounded_String;
               then abort
                  declare
                     cnt: Natural;
                     ind: Natural;
                     msg_in: Bounded_String;
                  begin
                     recv_msg.get(msg_in);
                     cnt:=msg_Str.count(msg_in,To_String(Null_Bounded_String&Character'val(0)));
                     for I in 1..cnt loop
                        ind:=index(msg_in,To_String(Null_Bounded_String&Character'val(0)));
                        if To_String(msg_in)(1)='/' then
                           -- TODO: if character 2 is 'n': rename user to first word, ignoring rest of line.
                           -- if character 2 is 't': first word is user to send message to. rest is message.
                           if To_String(msg_in)(2)='n' then
                              name:=To_Bounded_String(Slice(msg_in,3,ind-1));                              
                           end if;
                        else
                           Append(msg, Null_Bounded_String & name&":"&Slice(msg_in,1,ind-1));
                        end if;
                        msg_in:=To_Bounded_String(Slice(msg_in,ind+1,Length(msg_in)));
                     end loop;
                  end;
               end select;
            end;
         or
            terminate;
         end select;
      end loop;
   end;
   
   
   
   procedure new_connection(sock: Socket_Type) 
   is
      cli: constant	client_ref:=new client;
   begin
      Put_Line("Made new client.");
      cli.all.sock:=sock;
      connections.Include(Image(cli),cli);
      Put_Line("Added client to client list. Starting client connection...");
      cli.all.wrangler.start(sock);
      Put_Line("Client connection started. Gave client socket "&Image(sock));
   end;
   
   
   procedure send_message(msg: Bounded_String)
   is
   begin
      Put_Line("Sending message '"&To_String(msg)&"' to all connections.");
      for conn of connections loop
         Put_Line("sending message to connection "&Image(conn.all));
         conn.all.wrangler.send(msg);
         Put_Line("Sent message to "&Image(conn.all));
      end loop;
      Put_Line("Done.");
   end;
   
   function Image (cli: client) return String is
   begin
      return "Client with socket "&Image(cli.sock);
   end Image;
end connection;



