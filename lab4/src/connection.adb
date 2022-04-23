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
      
      send_msg: data;
      
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
               -- Put_Line("Checking if socket has readable data.");
               Check_Selector(selector,r,w,status,0.1);
               -- Put_Line("Check_Selector finished");
               if Is_Set(r, c_socket) and status=Completed then
                  Put_Line("Socket has readable data. Reading.");
                  -- can read from c_socket
                  declare
                     S: constant String:=String'Input(data_stream); 
                  begin
                     Put_Line("Read '"&S&"'.");
                     message:=To_Bounded_String(S);
                  end;
                  if Length(message)/=0 then                     
                     if To_String(message)(1)='/' and Length(message)>=4 then
                        Put_Line("command detected.");
                        case To_String(message)(2) is
                        when 'n' =>
                           Put_Line("name change detected.");
                           Put_Line("getting old name.");
                           declare
                              old_name: constant Bounded_String:=name;
                           begin                         
                              Put_Line("Old name is "&To_String(name));

                              Put_Line("Getting new name.");
                              if To_String(message)(3)=' ' then
                                 name:=To_Bounded_String(Slice(message,4,Length(message)));
                              else
                                 name:=To_Bounded_String(Slice(message,3,Length(message)));
                              end if;
                              
                              if connections.Contains(To_String(name)) then
                                 declare
                                    target: constant client_ref:=connections(To_String(old_name));
                                 begin
                                    target.all.wrangler.send("Name taken: '"&name&"'.");
                                 end;
                                 name:=old_name;
                              else
                                 Put_Line("New name is '"&To_String(name)&"'");
                                 Put_Line("Adding self under new name: get self");
                                 declare
                                    cli: constant client_ref:=connections(To_String(old_name));
                                 begin
                                    Put_Line("Got self ("&Image(cli => cli.all)&").");
                                    Put_Line("Including copy of self in connections.");
                                    connections.Include(To_String(name),cli);
                                    Put_Line("Included.");
                                 end;
                                 Put_Line("removing self under old name.");
                                 connections.Delete(To_String(old_name));
                                 Put_Line("Done. Notifying other clients of this change.");
                                 send_message("'"&old_name&"' is now known as '"&name&"'.");
                                 Put_Line("Notification sent.");
                              end if;
                           end;
                        when 't' =>
                           if To_String(message)(3)=' ' then
                              message:=To_Bounded_String(Slice(message,4,Length(message)));
                           else
                              message:=To_Bounded_String(Slice(message,3,Length(message)));
                           end if;
                           Put_Line("private message detected.");
                           declare
                              end_of_name: constant Natural:=Index(message," ");
                           begin
                              if end_of_name/=0 then                                 
                                 declare
                                    to_name: constant String:=Slice(message,1,end_of_name-1);
                                 begin
                                    Put_Line("message is to '"&to_name&"'.");
                                    if connections.Contains(to_name) then
                                       declare
                                          target: constant client_ref:=connections(to_name);
                                          priv_mesg: constant String:=Slice(message,end_of_name,Length(message));
                                       begin
                                          target.all.wrangler.send("private message from "&name&" : "&priv_mesg);
                                       end;
                                    else
                                       Put_Line("No such client.");
                                       declare
                                          target: constant client_ref:=connections(To_String(name));
                                       begin
                                          target.all.wrangler.send(To_Bounded_String("No such person as '"&to_name&"'."));
                                       end;
                                       
                                    end if;                              
                                 end;
                              else
                                 Put_Line("invalid syntax in private message request.");
                                 declare
                                    target: constant client_ref:=connections(To_String(name));
                                 begin
                                    target.all.wrangler.send(To_Bounded_String("Invalid syntax. Usage: /t [name] [message]"));
                                 end;

                              end if;
                           end;

                        when 'q' =>
                           declare
                              target: constant client_ref:=connections(To_String(name));
                           begin
                              target.all.wrangler.send(To_Bounded_String("Leaving server..."));
                           end;
                           Shutdown_Socket(Socket => socket, How=> Shut_Read_Write);
                           Close_Socket(Socket => socket);
                           connections.Delete(To_String(name));
                           send_message(name&" left.");
                        when others =>
                           Put_Line("Attempting to send the message to everyone.");               
                           send_message(name&" says: "&message);
                           Put_Line("Sent message.");
                        end case;
                     else
                        Put_Line("Attempting to send the message to everyone.");               
                        send_message(name&" says: "&message);
                        Put_Line("Sent message.");
                     end if;
                  end if;                  
               end if;
            end select;
         end loop;
      end communicate;
      
   begin
      Put_Line("client_wrangler task spawned. waiting to start.");
      accept start(sock: Socket_Type; name: String) do
         client_wrangler.socket:=sock;
         client_wrangler.name:=To_Bounded_String(name);
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
            terminate;
         end select;
      end loop;
   end;
   
   
   
   procedure new_connection(sock: Socket_Type; name: String) 
   is
      cli: constant	client_ref:=new client;
   begin
      Put_Line("Made new client.");
      cli.all.sock:=sock;
      connections.Include(name,cli);
      Put_Line("Added client to client list. Starting client connection...");
      cli.all.wrangler.start(sock,name);
      Put_Line("Client connection started. Gave client socket "&Image(sock));
   end;
   
   
   procedure send_message(msg: Bounded_String)
   is
   begin
      Put_Line("Sending message '"&To_String(msg)&"' to all connections.");
      for conn of connections loop
         declare
            task send is
               entry start(con: client_ref);
            end send;
            
            task body send is
               c: client_ref;
            begin
               accept start(con: client_ref) do
                  c:=con;
               end start;
               
               Put_Line("sending message to connection "&Image(c.all));
               c.all.wrangler.send(msg);
               Put_Line("Sent message to "&Image(c.all));
            end send;
         begin
            send.start(conn);
         end;
      end loop;
      Put_Line("Done.");
   end;
   
   function Image (cli: client) return String is
   begin
      return "Client with socket "&Image(cli.sock);
   end Image;
end connection;



