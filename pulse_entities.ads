-- pulse_entities.ads: Base Pulse-Coupled Entity - UNIFIED TYPE SYSTEM
with Pulse_Types; use Pulse_Types;

package Pulse_Entities is
   
   -- USE UNIFIED TYPE: All entities now use Pulse_Types.Entity_Record
   -- No separate Base_Entity type - semantic truth achieved
   
   -- Core entity operations
   procedure Reset_Phase (Entity : in out Entity_Record);
   function Should_Flash (Entity : Entity_Record) return Boolean;
   procedure Apply_Pulse (Entity : in out Entity_Record; Sender_ID : Entity_ID);
   
end Pulse_Entities;
