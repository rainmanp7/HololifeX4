-- Base Pulse-Coupled Entity - All entities inherit from this
with Pulse_Types; use Pulse_Types;

package Pulse_Entities is
   
   type Base_Entity is abstract tagged record
      ID : Entity_ID;
      Current_Phase : Phase_Type;
      Natural_Freq : Frequency_Type;
      Coupling_Str : Coupling_Type;
      Flash_Count : Natural;
      Is_Active : Boolean;
   end record;
   
   -- Abstract methods each entity must implement
   procedure Initialize (Entity : in out Base_Entity) is abstract;
   procedure Evolve_Phase (Entity : in out Base_Entity) is abstract;
   function Generate_Insight (Entity : Base_Entity) return String is abstract;
   procedure Receive_Pulse (Entity : in out Base_Entity; Sender_ID : Entity_ID) is abstract;
   
   -- Common concrete methods
   procedure Reset_Phase (Entity : in out Base_Entity);
   function Should_Flash (Entity : Base_Entity) return Boolean;
   procedure Apply_Pulse (Entity : in out Base_Entity; Sender_ID : Entity_ID);
   
end Pulse_Entities;