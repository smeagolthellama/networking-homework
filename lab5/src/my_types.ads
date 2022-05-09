with Ada.Numerics.Generic_Complex_Types;
with Ada.Text_IO.Complex_IO;

package My_Types is
   type My_Range is range 0 .. 720;
   type My_R_Range is new My_Range range 1 .. My_Range'Last;
   type My_Float is digits 5;
   type My_Arr is array (My_R_Range) of Boolean with Pack;
   type My_Mat is array (My_R_Range,My_R_Range) of Boolean with Pack;
   package m_c is new Ada.Numerics.Generic_Complex_Types(Real => My_Float);
   package c_io is new Ada.Text_IO.Complex_IO(m_c);
end My_Types;
