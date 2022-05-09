with Ada.Text_IO; use Ada.Text_IO;
with Ada.Streams.Stream_IO; use Ada.Streams.Stream_IO;
with GNAT.Sockets; use GNAT.Sockets;
with Ada.Command_Line; use Ada.Command_Line;
with My_Types; use My_Types; use My_Types.m_c;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

procedure Server is
   socket: socket_Type;
   addr: Sock_Addr_Type;
   opt: Option_Type;
   clientnum: My_Range;

   EndProgram: exception;

   procedure Usage is
   begin
      Put_Line(Standard_Error,"Usage: "&Command_Name&" [number of clients<=720] ");
      Set_Exit_Status(Failure);
      raise EndProgram;
   end;

   protected mandelbrot is
      procedure add(I: My_Range; R: My_Arr);
      entry get(set: out My_Mat);
   private
      matrix: My_Mat;
      set_vals: My_Arr:=(others=>False);
   end;

   task type handler is
      entry Start(sock: Socket_Type; I: My_Range);
   end handler;

   task body handler is
      socket: Socket_Type;
      row: My_Range;
      start_cplx, end_cplx: Complex;
      data_stream: GNAT.Sockets.Stream_Access;

      function get_imag (I:My_Range) return My_Float is
         x: constant My_Float:=My_Float(I);
         c: constant My_Float:=My_Float(clientnum);
      begin
            return 1.2*(-2.0*(x/c)+1.0);
      end get_imag;

   begin
      accept Start(sock: Socket_Type; I: My_Range) do
         socket:=sock;
         row:=I;
      end Start;
      data_stream:=Stream(socket);
      start_cplx:=(Re => -2.0,Im => get_imag(row-1));
      end_cplx:=(Re => 2.0, Im=> get_imag(row));
      Complex'Output(data_stream,start_cplx);
      Complex'Output(data_stream,end_cplx);
      declare
         can_read: Boolean:=True;
         r, w: Socket_Set_Type;
         status: Selector_Status;
         selector: Selector_Type;
      begin
         Empty(w);
         Create_Selector(Selector => selector);
         while can_read loop
            Empty(r);
            Set(r,socket);
            Check_Selector(selector,r,w,status,5.0);
            if status=Aborted then
               --              Put_Line(Standard_Error,"selector Aborted.");
               can_read:=False;
            elsif status=Completed then
                  if not Is_Set(r,socket) then
                  --                   Put_Line(Standard_Error,"Socket not in set. Aborting.");
                  can_read:=False;
               else
                  declare
                     request: Request_Type(Name=>N_Bytes_To_Read);
                  begin
                     Control_Socket(socket,request);
                     if request.Size=0 then
                           --                           Put_Line(Standard_Error,"Nothing to read from socket. Ending.");
                        can_read:=False;
                     else
                        declare
                           ind: constant My_Range:=My_Range'Input(data_stream);
                           arr: constant My_Arr:=My_Arr'Input(data_stream);
                        begin
                           --Put_Line(Standard_Error,"Read "&My_Range'Image(ind)&"'th line of matrix.");
                           mandelbrot.add(ind,arr);
                        end;
                     end if;
                  end;
               end if;
            end if;
         end loop;
      end;
   end handler;



   protected body mandelbrot is
      procedure add(I: My_Range; R: My_Arr) is
      begin
         set_vals(I):=True;
         for J in R'Range loop
            matrix(I,J):=R(J);
         end loop;
         for I in set_vals'Range loop
            if set_vals(I)=False then
               Put_Line(Standard_Error,"First non-set line is "&I'Image);
               exit;
            end if;
         end loop;
      end;

      entry get(set: out My_Mat) when (for all I in set_vals'Range => set_vals(I)=True)
      is
      begin
         set:=matrix;
      end get;
   end mandelbrot;
begin
   if Argument_Count<1 then
      Usage;
   end if;
   begin
      clientnum:=My_Range'Value(Argument(1));
   exception
      when others=>
         Usage;
   end;
   Create_Socket(socket);
   addr.Addr:=Any_Inet_addr;
   addr.Port:=7778;
   opt:=(Name=>Reuse_Address,Enabled=>True);
   Set_Socket_Option(socket,IP_Protocol_For_IP_Level,opt);
   opt:=(Name=>Keep_Alive,Enabled=>True);
   Set_Socket_Option(socket,IP_Protocol_For_TCP_Level,opt);
   Bind_Socket(socket,addr);
   Listen_Socket(socket);
   declare

   begin
      for I in 1..clientnum loop
         declare
            new_sock: Socket_Type;
            new_addr: Sock_Addr_Type;
            handle: handler;
         begin
            Accept_Socket(socket,new_sock,new_addr);
            Put_Line("new connection from "&Image(new_addr));
            handle.Start(new_sock,I);
         end;
      end loop;
   end;
   declare
      mandel_mat: My_Mat;
      mandel_file: Ada.Streams.Stream_IO.File_Type;
   begin
      mandelbrot.get(mandel_mat);
      Create(mandel_file,Out_File,"mandelbrot.pbm");
      Put_Line(Standard_Error,"got mandelbrot matrix.");
      String'Write(Stream(mandel_file),"P5"&LF);
      String'Write(Stream(mandel_file),"720 720"&LF);
      String'Write(Stream(mandel_file),"1"&LF);
      My_Mat'Write(Stream(mandel_file),mandel_mat);
   end;

exception
   when EndProgram =>
      null;
end Server;
