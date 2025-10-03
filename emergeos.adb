-- hardware_entity.adb: Hardware Reality Anchor Implementation
-- Bare-metal compatible - no secondary stack, no string operations
package body Hardware_Entity is

   procedure Initialize (Entity : in out Hardware_Anchor) is
   begin
      Entity.Base := (
         ID => ENTITY_HARDWARE,
         Phase => 500,  -- Start at phase 0.5
         Frequency => HARDWARE_FREQUENCY,
         Coupling => HARDWARE_COUPLING,
         Flash_Count => 0,
         Is_Active => True
      );
      Entity.Memory_Validated := False;
      Entity.Devices_Detected := 0;
      Entity.Resource_Coherence := 0;
      Entity.Last_Validation_Cycle := 0;
   end Initialize;

   procedure Evolve_Phase (Entity : in out Hardware_Anchor) is
   begin
      if Entity.Base.Is_Active then
         -- FIXED: Use explicit type conversion for arithmetic
         Entity.Base.Phase := Phase_Type(Natural(Entity.Base.Phase) + 1);
         
         -- Cap at threshold - FIXED: Remove impossible condition
         if Entity.Base.Phase >= PHASE_THRESHOLD then
            Entity.Base.Phase := PHASE_THRESHOLD;
         end if;
         
         -- Every 100 cycles, validate hardware
         Entity.Last_Validation_Cycle := Entity.Last_Validation_Cycle + 1;
         if Entity.Last_Validation_Cycle >= 100 then
            Entity.Memory_Validated := Validate_Memory_Layout;
            Entity.Devices_Detected := Detect_Hardware_Devices;
            Entity.Resource_Coherence := Calculate_Resource_Coherence;
            Entity.Last_Validation_Cycle := 0;
         end if;
      end if;
   end Evolve_Phase;

   function Check_Flash (Entity : Hardware_Anchor) return Boolean is
   begin
      return Entity.Base.Phase >= PHASE_THRESHOLD;
   end Check_Flash;

   function Get_Insight_Type (Entity : Hardware_Anchor) return Insight_Type is
   begin
      if not Entity.Memory_Validated then
         return MEMORY_VALIDATION_FAILED;
      elsif Entity.Devices_Detected < 2 then
         return LIMITED_DEVICES;
      elsif Entity.Resource_Coherence < 80 then
         return LOW_COHERENCE;
      else
         return SYSTEM_STABLE;
      end if;
   end Get_Insight_Type;

   procedure Receive_Pulse (Entity : in out Hardware_Anchor; Sender_ID : Entity_ID) is
   begin
      if Entity.Base.Is_Active and Entity.Base.Phase < PHASE_THRESHOLD then
         -- FIXED: Use explicit type conversion
         Entity.Base.Phase := Phase_Type(Natural(Entity.Base.Phase) + Natural(Entity.Base.Coupling));
         
         -- Cap at threshold
         if Entity.Base.Phase >= PHASE_THRESHOLD then
            Entity.Base.Phase := PHASE_THRESHOLD;
         end if;
      end if;
   end Receive_Pulse;

   -- Hardware validation functions (stub implementations)
   function Validate_Memory_Layout return Boolean is
   begin
      return True;  -- Placeholder
   end Validate_Memory_Layout;

   function Detect_Hardware_Devices return Natural is
   begin
      return 2;  -- Placeholder
   end Detect_Hardware_Devices;

   function Calculate_Resource_Coherence return Natural is
   begin
      return 85;  -- Placeholder
   end Calculate_Resource_Coherence;

end Hardware_Entity;
