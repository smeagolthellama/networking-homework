with Ada.Numerics.Generic_Complex_Types;

package My_Types is
   type My_Float is digits 5;
   package m_c is new Generic_Complex_Types(Real => My_Float);
   use m_c;
end My_Types;
