-- hardware_entity.adb: Hardware Reality Anchor Implementation
with Pulse_Entities; use Pulse_Entities;

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
         -- Hardware entity evolves slowly and deliberately
         Entity.Base.Phase := Entity.Base.Phase + Entity.Base.Frequency;
         
         -- Cap at threshold
         if Entity.Base.Phase > PHASE_THRESHOLD then
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

   function Generate_Insight (Entity : Hardware_Anchor) return String is
   begin
      if Entity.Base.Phase >= PHASE_THRESHOLD then
         -- Generate hardware-specific insights
         if not Entity.Memory_Validated then
            return "HARDWARE: Memory layout validation failed - check address mapping";
         elsif Entity.Devices_Detected < 2 then
            return "HARDWARE: Limited devices detected - VGA/Serial may be offline";
         elsif Entity.Resource_Coherence < 80 then
            return "HARDWARE: Resource coherence low - optimize memory allocation";
         else
            return "HARDWARE: System stable - " & 
                   Natural'Image(Entity.Devices_Detected) & " devices active";
         end if;
      else
         return "";  -- No insight yet
      end if;
   end Generate_Insight;

   procedure Receive_Pulse (Entity : in out Hardware_Anchor; Sender_ID : Entity_ID) is
   begin
      if Entity.Base.Is_Active and Entity.Base.Phase < PHASE_THRESHOLD then
         -- Apply pulse using base entity procedure
         Apply_Pulse(Entity.Base, Sender_ID);
      end if;
   end Receive_Pulse;

   -- Hardware validation functions
   function Validate_Memory_Layout return Boolean is
   begin
      -- Simple memory validation for Phase 3
      -- Check if key memory regions are accessible
      return True;  -- Placeholder - will implement actual checks in Phase 4
   end Validate_Memory_Layout;

   function Detect_Hardware_Devices return Natural is
   begin
      -- Simple device detection for Phase 3
      -- VGA at 0xB8000 is always present in our emulator
      -- Serial at 0x3F8 might be available
      return 2;  -- Placeholder - VGA + Serial assumed
   end Detect_Hardware_Devices;

   function Calculate_Resource_Coherence return Natural is
   begin
      -- Simple resource coherence calculation
      -- Based on memory allocation efficiency
      return 85;  -- Placeholder - will implement actual calculation in Phase 4
   end Calculate_Resource_Coherence;

   function Check_Hardware_Consistency (Entity : Hardware_Anchor) return Boolean is
   begin
      return Entity.Memory_Validated and (Entity.Devices_Detected >= 1);
   end Check_Hardware_Consistency;

end Hardware_Entity;
