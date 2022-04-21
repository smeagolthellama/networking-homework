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
			accept comm_start(sock: Socket_Type) do
				c_socket:=sock;
			end comm_start;
			Create_Selector(selector);
			data_stream:=Stream(c_socket);
			loop
				select
					accept send_message do
						send_msg.get(message);
						Set(r,c_socket);
						Set(w,c_socket);
						Check_Selector(selector,r,w,status,1.0);
						if Is_Set(w, c_socket) and status=Completed then
							String'Output(data_stream,To_String(message));
						else
							send_msg.set(message);
							requeue send_message;
						end if;
					end send_message;
				else
					Set(r,c_socket);
					Set(w,c_socket);
					Check_Selector(selector,r,w,status,1.0);
					if Is_Set(r, c_socket) and status=Completed then
						-- can read from c_socket
						declare
                     S: constant String:=String'Input(data_stream); 
						begin
							message:=To_Bounded_String(S);
						end;
						recv_msg.set(message);
					end if;
				end select;
			end loop;
		end communicate;

	begin
		accept start(sock: Socket_Type) do
			client_wrangler.socket:=sock;
		end start;
		communicate.comm_start(socket);
		loop
			select
				accept send(msg: Bounded_String) do
               send_msg.set(msg);
               communicate.send_message;
				end;
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
									null;
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
		connections.append(cli);
		cli.all.wrangler.start(sock);
	end;


	procedure send_message(msg: Bounded_String)
	is
	begin
		for conn of connections loop
			conn.all.wrangler.send(msg);
		end loop;
	end;
end connection;



