with Ada.Numerics.Generic_Complex_Types;

package My_Types is
   type My_Range is range 1 .. 720;
   type My_Float is digits 5;
   type My_Arr is array (My_Range) of Boolean;
   package m_c is new Ada.Numerics.Generic_Complex_Types(Real => My_Float);
end My_Types;
