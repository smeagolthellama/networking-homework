with GNAT.Sockets; use GNAT.Sockets;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line; use Ada.Command_Line;
with My_Types; use My_Types; use My_Types.m_c;

procedure client is
   sock: Socket_Type;
   addr: Sock_Addr_Type;
   data_stream: Stream_Access;

begin
   if Argument_Count/=1 then
      Put_Line(Current_Error,"usage: " & Command_Name & " [host]");
      Set_Exit_Status(1);
      return;
   end if;
   Create_Socket(sock);
   if Is_IPv4_Address(Argument(1)) or Is_IPv6_Address(Argument(1)) then
      addr.Addr:=Inet_Addr(Argument(1));
   else
      addr.Addr:=Addresses(Get_Host_By_Name(Argument(1)),1);
   end if;
   addr.Port:=Port_Type'val(7778);
   Connect_Socket(sock,addr);
   data_stream:=Stream(sock);
   declare
      start_cplx: constant Complex:=Complex'Input(data_stream);
      end_cplx: constant Complex:=Complex'Input(data_stream);
      index_cplx: Complex:=(-2.0,1.2);
      diff_r_cplx: constant Complex:=(4.0/720.0,0.0);
      diff_i_cplx: constant Complex:=(0.0,2.4/720.0);
      count: My_Range:=1;
      row_index: My_Range;
      arr: My_Arr;
      iter: Integer:=1;
      z: Complex;
   begin
      -- find the points within the rectangle given.
      while index_cplx.Im>start_cplx.Im loop
         index_cplx:=index_cplx+diff_i_cplx;
         count:=count+1;
      end loop;

      while index_cplx.Im<=end_cplx.Im loop
         row_index:=1;
         while index_cplx.Re<=end_cplx.Re loop
            iter:=1;
            z:=index_cplx;
            while iter<Integer(My_Range'Last) and Modulus(z)<=2.0 loop
               z:=z**2+index_cplx;
               iter:=iter+1;
            end loop;
            arr(row_index):=(Modulus(z)<=2.0);
            index_cplx:=index_cplx+diff_r_cplx;
            row_index:=row_index+1;
         end loop;
         My_Range'Output(data_stream,count);
         My_Arr'Output(data_stream,arr);
         count:=count+1;
         index_cplx:=index_cplx+diff_i_cplx;
         index_cplx.Re:=-2.0;
      end loop;
   end;

end client;
