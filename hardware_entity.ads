-- hardware_entity.ads: Hardware Reality Anchor
-- First specialized pulse-coupled entity for HelloXLife OS
with Pulse_Types; use Pulse_Types;

package Hardware_Entity is
   
   type Hardware_Anchor is record  -- CHANGED: No inheritance, use composition
      Base : Pulse_Types.Entity_Record;
      Memory_Validated : Boolean;
      Devices_Detected : Natural;
      Resource_Coherence : Natural;
      Last_Validation_Cycle : Natural;
   end record;
   
   -- Entity lifecycle procedures
   procedure Initialize (Entity : in out Hardware_Anchor);
   procedure Evolve_Phase (Entity : in out Hardware_Anchor);
   function Generate_Insight (Entity : Hardware_Anchor) return String;
   procedure Receive_Pulse (Entity : in out Hardware_Anchor; Sender_ID : Entity_ID);
   
   -- Hardware-specific validation functions
   function Validate_Memory_Layout return Boolean;
   function Detect_Hardware_Devices return Natural;
   function Calculate_Resource_Coherence return Natural;
   function Check_Hardware_Consistency (Entity : Hardware_Anchor) return Boolean;
   
   -- Entity constants
   HARDWARE_FREQUENCY : constant Frequency_Type := 3;  -- Deliberate, careful
   HARDWARE_COUPLING  : constant Coupling_Type := 8;   -- Moderate influence
   
end Hardware_Entity;
