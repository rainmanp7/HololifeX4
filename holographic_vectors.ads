-- holographic_vectors.ads - 512-Dimensional Vector Mathematics
with Types;

package Holographic_Vectors is
   pragma Preelaborate;
   
   use Types;
   
   -- 512-dimensional vector type
   type Vector_512 is array (1 .. HOLOGRAPHIC_DIMENSIONS) of Float;
   
   -- Holographic vector record (from C kernel)
   type Holographic_Vector is record
      Data              : Vector_512;
      Hash_Signature    : DWord;
      Active_Dimensions : Natural;
      Valid             : Boolean;
   end record;
   
   -- Null vector constant
   Null_Vector : constant Holographic_Vector := 
     (Data              => (others => 0.0),
      Hash_Signature    => 0,
      Active_Dimensions => 0,
      Valid             => False);
   
   -- Vector operations
   function Create_Vector(Input : String) return Holographic_Vector;
   function Hash_FNV(Data : String) return DWord;
   function Cosine_Similarity(A, B : Holographic_Vector) return Float;
   
private
   -- FNV-1a hash constants (from C kernel)
   FNV_Offset_Basis : constant DWord := 16#811C9DC5#;
   FNV_Prime        : constant DWord := 16#01000193#;
   
end Holographic_Vectors;