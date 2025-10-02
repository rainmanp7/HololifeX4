-- patterns.ads: Pre-defined attractor patterns
package Patterns is
   pragma Preelaborate;
   type Vector_512 is array (1..512) of Float;
   type Pattern_Type is (Sine_Wave, Gaussian, Random, Sparse);
   function Generate_Pattern(Pattern_Kind : Pattern_Type) return Vector_512;
   Sine_Pattern    : constant Vector_512;
   Gaussian_Pattern : constant Vector_512;
   Sparse_Pattern  : constant Vector_512;
end Patterns;