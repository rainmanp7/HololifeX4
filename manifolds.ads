-- manifolds.ads: Vector mathematics package specification
package Manifolds is
   pragma Pure;
   
   type Vector_512 is array (1..512) of Float;
   type Manifold_Point is record
      Position  : Vector_512;
      Velocity  : Vector_512; 
      Attractors : Vector_512;
   end record;
   
   function Initialize_Manifold return Manifold_Point;
   function Compute_Gradient(Point : Manifold_Point) return Vector_512;
   function Distance(P1, P2 : Manifold_Point) return Float;
   function Compute_State_Complexity(Position : Vector_512) return Float;
   procedure Update_Manifold(Point : in out Manifold_Point);
end Manifolds;