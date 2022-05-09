with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Sockets; use GNAT.Sockets;
with Ada.Command_Line; use Ada.Command_Line;
with My_Types; use My_Types; use My_Types.m_c;

procedure Server is
   socket: socket_Type;
   addr: Sock_Addr_Type;
   opt: Option_Type;
   clientnum: Integer;

   EndProgram: exception;

   procedure Usage is
   begin
      Put_Line(Standard_Error,"Usage: "&Command_Name&" [number of clients] ");
      Set_Exit_Status(Failure);
      raise EndProgram;
   end;
begin
   if Argument_Count<1 then
      Usage;
   end if;
   begin
      clientnum:=Integer'Value(Argument(1));
   exception
      when others=>
         Usage;
   end;
   Create_Socket(socket);
   addr.Addr:=Any_Inet_addr;
   addr.Port:=7777;
   opt:=(Name=>Reuse_Address,Enabled=>True);
   Set_Socket_Option(socket,IP_Protocol_For_IP_Level,opt);
   opt:=(Name=>Keep_Alive,Enabled=>True);
   Set_Socket_Option(socket,IP_Protocol_For_TCP_Level,opt);
   Bind_Socket(socket,addr);
   Listen_Socket(socket);
   declare
      task type handler is
         entry Start(sock: Socket_Type; I: Integer);
      end handler;

      task body handler is
         socket: Socket_Type;
         row: Integer;
         start_cplx, end_cplx: Complex;
         data_stream: Stream_Access;
      begin
         accept Start(sock: Socket_Type; I: Integer) do
            socket:=sock;
            row:=I;
         end Start;
         data_stream:=Stream(socket);
         start_cplx:=Compose_From_Cartesian(Re => -1.0,Im => My_Float(row-1)/My_Float(720));
         end_cplx:=Compose_From_Cartesian(Re => 1.0, Im=> My_Float(row)/My_Float(720));
         Complex'Output(data_stream,start_cplx);
         Complex'Output(data_stream,end_cplx);
      end;

   begin
      for I in 1..clientnum loop
         declare
            new_sock: Socket_Type;
            new_addr: Sock_Addr_Type;
            handle: handler;
         begin
            Accept_Socket(socket,new_sock,new_addr);
            handle.Start(new_sock,I);
         end;
      end loop;
   end;

exception
   when EndProgram =>
      null;
end Server;
