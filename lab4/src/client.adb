with GNAT.Sockets; use GNAT.Sockets;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line; use Ada.Command_Line;
with Ada.Strings.Bounded;
with Ada.Task_Identification; use Ada.Task_Identification;

procedure client is
   package my_str is
     new Ada.Strings.Bounded.Generic_Bounded_Length(Max => 1024);
   use my_str;
   in_str: Bounded_String;
   socket: Socket_Type;
   addr: Sock_Addr_Type;
   task read_loop is
      entry start;
   end read_loop;

   task body read_loop is
   begin
      accept start;
      loop
         declare
            out_str: constant String:=String'Input(Stream(socket));
         begin
            Put_Line(out_str);
         end;
      end loop;

   end read_loop ;

begin
   if Argument_Count/=1 then
      Put_Line(Current_Error,"usage: " & Command_Name & " [host]");
      Set_Exit_Status(1);
      Abort_Task(Current_Task);
      return;
   end if;
   Create_Socket(socket);
   addr.Addr:=Addresses(Get_Host_By_Name(Argument(1)),1);
   addr.Port:=Port_Type'val(7777);
   Connect_Socket(socket,addr);
   read_loop.start;
   loop
      declare
         read_String: constant String:=Get_Line(Current_Input);
      begin
         in_str:=To_Bounded_String(read_String);
         String'Output(Stream(socket), To_String(in_str));
      end;
   end loop;

end client;
