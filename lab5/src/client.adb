with GNAT.Sockets; use GNAT.Sockets;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line; use Ada.Command_Line;
with My_Types; use My_Types; use My_Types.m_c; use My_Types.c_io;

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
      diff_r_cplx: constant Complex:=(abs(start_cplx.Re-end_cplx.Re)/720.0,0.0);
      diff_i_cplx: constant Complex:=(0.0,abs(start_cplx.Im-end_cplx.Im)/720.0);
      count: Integer:=1;
      row_index: Integer;
      arr: My_Arr;
      iter: Integer:=1;
      z: Complex;
   begin
      Put_Line(Standard_Error, "got start position: ");
      Put(Standard_Error,start_cplx);
      Put_Line(Standard_Error,"");
      Put_Line(Standard_Error, "got end position: ");
      Put(Standard_Error,end_cplx);
      Put_Line(Standard_Error,"");
      Put(Standard_Error,"dRe=");
      Put(Standard_Error,diff_r_cplx);
      Put(Standard_Error,"dIm=");
      Put(Standard_Error,diff_i_cplx);
      -- find the points within the rectangle given.
      while index_cplx.Im+diff_i_cplx.Im>start_cplx.Im loop
         index_cplx:=index_cplx+diff_i_cplx;
         count:=count+1;
      end loop;
      Put_Line("starting at line "&count'Image);
      while index_cplx.Im+diff_i_cplx.Im>=end_cplx.Im loop
         row_index:=1;
         while index_cplx.Re<end_cplx.Re and row_index<=720 loop
            iter:=1;
            z:=index_cplx;
            while iter<Integer(My_Range'Last) and Modulus(z)<=2.0 loop
               z:=z**2+index_cplx;
               iter:=iter+1;
            end loop;
            arr(My_Range(row_index)):=(Modulus(z)<=2.0);
            index_cplx:=index_cplx+diff_r_cplx;
            --Put_Line("row_index is now "&row_index'Image);
            row_index:=row_index+1;
         end loop;
         Put_Line("Calculated line "&count'Image&". Sending it to the socket.");
         My_Range'Output(data_stream,My_Range(count));
         My_Arr'Output(data_stream,arr);
         count:=count+1;
         index_cplx:=index_cplx+diff_i_cplx;
         index_cplx.Re:=-2.0;
      end loop;
   end;

end client;
