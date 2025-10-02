-- manifolds.adb: Vector mathematics package implementation
package body Manifolds is
   function Initialize_Manifold return Manifold_Point is
      Point : Manifold_Point;
      Seed : Integer := 42;
   begin
      for I in 1..512 loop
         Point.Position(I) := Float((Seed * I) mod 2000 - 1000) / 1000.0;
         Point.Velocity(I) := 0.0;
         Point.Attractors(I) := 0.5;
         Seed := Seed * 1103515245 + 12345;
      end loop;
      return Point;
   end Initialize_Manifold;

   function Compute_Gradient(Point : Manifold_Point) return Vector_512 is
      Gradient : Vector_512;
   begin
      for I in 1..512 loop
         Gradient(I) := Point.Attractors(I) - Point.Position(I);
      end loop;
      return Gradient;
   end Compute_Gradient;

   function Distance(P1, P2 : Manifold_Point) return Float is
      Sum_Squares : Float := 0.0;
   begin
      for I in 1..512 loop
         Sum_Squares := Sum_Squares + (P1.Position(I) - P2.Position(I)) ** 2;
      end loop;
      return Sqrt(Sum_Squares);
   end Distance;

   function Compute_State_Complexity(Position : Vector_512) return Float is
      Mean, Variance : Float := 0.0;
   begin
      for I in 1..512 loop Mean := Mean + Position(I); end loop;
      Mean := Mean / 512.0;
      for I in 1..512 loop 
         Variance := Variance + (Position(I) - Mean) ** 2; 
      end loop;
      return (Variance / 512.0) / 2.0;
   end Compute_State_Complexity;

   procedure Update_Manifold(Point : in out Manifold_Point) is
      Gradient : Vector_512;
   begin
      Gradient := Compute_Gradient(Point);
      for I in 1..512 loop
         Point.Velocity(I) := 0.9 * Point.Velocity(I) + 0.1 * Gradient(I);
         Point.Position(I) := Point.Position(I) + Point.Velocity(I);
         if Point.Position(I) > 1.0 then
            Point.Position(I) := 1.0; Point.Velocity(I) := -Point.Velocity(I) * 0.5;
         elsif Point.Position(I) < -1.0 then
            Point.Position(I) := -1.0; Point.Velocity(I) := -Point.Velocity(I) * 0.5;
         end if;
      end loop;
   end Update_Manifold;
end Manifolds;