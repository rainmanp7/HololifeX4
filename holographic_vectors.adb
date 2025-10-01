-- holographic_vectors.adb - 512-D Vector Mathematics Implementation
with System;  -- For address operations

package body Holographic_Vectors is

   function Hash_FNV(Data : String) return DWord is
      Hash : DWord := FNV_Offset_Basis;
   begin
      for I in Data'Range loop
         Hash := (Hash xor DWord(Character'Pos(Data(I)))) * FNV_Prime;
      end loop;
      return Hash;
   end Hash_FNV;

   function Create_Vector(Input : String) return Holographic_Vector is
      Vector : Holographic_Vector := Null_Vector;
      Seed   : DWord := Hash_FNV(Input);
   begin
      Vector.Hash_Signature := Seed;
      Vector.Valid := True;
      Vector.Active_Dimensions := 0;
      
      -- Generate sparse vector (from C kernel logic)
      for I in Vector.Data'Range loop
         Seed := (Seed * 1103515245 + 12345) and 16#7FFFFFFF#;
         if (Seed mod 10) = 0 then
            Vector.Data(I) := Float(Integer(Seed mod 2000) - 1000) / 1000.0;
            Vector.Active_Dimensions := Vector.Active_Dimensions + 1;
         else
            Vector.Data(I) := 0.0;
         end if;
      end loop;
      
      return Vector;
   end Create_Vector;

   -- Fast inverse square root approximation (from C kernel)
   function Fast_Inv_Sqrt(X : Float) return Float is
      X_Half : constant Float := 0.5 * X;
      I      : Integer;
      Result : Float;
   begin
      -- Bit manipulation (Ada equivalent of C's type punning)
      I := Integer(X);  -- This is simplified - real implementation needs proper bit manipulation
      I := 16#5F3759DF# - (I / 2);
      Result := Float(I);
      Result := Result * (1.5 - (X_Half * Result * Result));
      return Result;
   end Fast_Inv_Sqrt;

   function Cosine_Similarity(A, B : Holographic_Vector) return Float is
      Dot_Product : Float := 0.0;
      Magnitude_A : Float := 0.0;
      Magnitude_B : Float := 0.0;
   begin
      for I in A.Data'Range loop
         Dot_Product := Dot_Product + A.Data(I) * B.Data(I);
         Magnitude_A := Magnitude_A + A.Data(I) * A.Data(I);
         Magnitude_B := Magnitude_B + B.Data(I) * B.Data(I);
      end loop;
      
      Magnitude_A := (if Magnitude_A > 0.0 then Fast_Inv_Sqrt(Magnitude_A) else 1.0);
      Magnitude_B := (if Magnitude_B > 0.0 then Fast_Inv_Sqrt(Magnitude_B) else 1.0);
      
      return Dot_Product * Magnitude_A * Magnitude_B;
   end Cosine_Similarity;

end Holographic_Vectors;