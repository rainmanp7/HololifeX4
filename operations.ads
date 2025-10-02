-- operations.ads: Basic linear algebra operations
package Operations is
   pragma Pure;
   type Vector_512 is array (1..512) of Float;
   function Vector_Add(A, B : Vector_512) return Vector_512;
   function Vector_Subtract(A, B : Vector_512) return Vector_512;
   function Scalar_Multiply(Scalar : Float; Vector : Vector_512) return Vector_512;
   function Dot_Product(A, B : Vector_512) return Float;
   function Magnitude(Vector : Vector_512) return Float;
   function Normalize(Vector : Vector_512) return Vector_512;
end Operations;