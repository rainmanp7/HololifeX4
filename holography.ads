-- holography.ads: Holographic memory interface
package Holography is
   pragma Preelaborate;
   type Vector_512 is array (1..512) of Float;
   procedure Store_Pattern(Entity_ID : Natural; Pattern : Vector_512);
   function Recall_Pattern(Entity_ID : Natural) return Vector_512;
   function Pattern_Correlation(P1, P2 : Vector_512) return Float;
   procedure Initialize_Holography;
end Holography;