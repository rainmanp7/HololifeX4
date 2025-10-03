-- hardware_entity.ads: Hardware Reality Anchor
-- Bare-metal compatible implementation
with Pulse_Types; use Pulse_Types;

package Hardware_Entity is
   
   type Hardware_Anchor is record
      Base : Pulse_Types.Entity_Record;
      Memory_Validated : Boolean;
      Devices_Detected : Natural;
      Resource_Coherence : Natural;
      Last_Validation_Cycle : Natural;
   end record;
   
   -- Entity lifecycle procedures
   procedure Initialize (Entity : in out Hardware_Anchor);
   procedure Evolve_Phase (Entity : in out Hardware_Anchor);
   function Check_Flash (Entity : Hardware_Anchor) return Boolean;
   procedure Receive_Pulse (Entity : in out Hardware_Anchor; Sender_ID : Entity_ID);
   
   -- Hardware validation functions
   function Validate_Memory_Layout return Boolean;
   function Detect_Hardware_Devices return Natural;
   function Calculate_Resource_Coherence return Natural;
   
   -- Entity constants
   HARDWARE_FREQUENCY : constant Frequency_Type := 3;
   HARDWARE_COUPLING  : constant Coupling_Type := 8;
   
   -- Insight types (avoid string operations)
   type Insight_Type is (NO_INSIGHT, MEMORY_VALIDATION_FAILED, LIMITED_DEVICES, 
                        LOW_COHERENCE, SYSTEM_STABLE);
   
end Hardware_Entity;
