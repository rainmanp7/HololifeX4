-- Base Pulse-Coupled Entity - SIMPLIFIED for Phase 1
with Pulse_Types; use Pulse_Types;

package Pulse_Entities is
   
   type Base_Entity is record
      ID : Entity_ID;
      Current_Phase : Phase_Type;
      Natural_Freq : Frequency_Type;
      Coupling_Str : Coupling_Type;
      Flash_Count : Natural;
      Is_Active : Boolean;
   end record;
   
   -- SIMPLIFIED: Remove abstract methods for now
   procedure Reset_Phase (Entity : in out Base_Entity);
   function Should_Flash (Entity : Base_Entity) return Boolean;
   procedure Apply_Pulse (Entity : in out Base_Entity; Sender_ID : Entity_ID);
   
end Pulse_Entities;
