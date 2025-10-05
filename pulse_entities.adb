-- pulse_entities.adb: Base Entity Implementation - UNIFIED TYPE SYSTEM
package body Pulse_Entities is

   procedure Reset_Phase (Entity : in out Entity_Record) is
   begin
      Entity.Phase := 0;
   end Reset_Phase;

   function Should_Flash (Entity : Entity_Record) return Boolean is
   begin
      return Entity.Phase >= PHASE_THRESHOLD and Entity.Is_Active;
   end Should_Flash;

   procedure Apply_Pulse (Entity : in out Entity_Record; Sender_ID : Entity_ID) is
      Phase_Boost : Phase_Type;
   begin
      if Entity.Phase < PHASE_THRESHOLD and Entity.Is_Active then
         -- FIXED: Use correct field names from Entity_Record
         Phase_Boost := Phase_Type(
            (Natural(Entity.Phase) * Natural(Entity.Coupling)) / 100
         );
         
         Entity.Phase := Entity.Phase + Phase_Boost;
         
         -- Cap at threshold (FIXED: use ">" not ">=")
         if Entity.Phase > PHASE_THRESHOLD then
            Entity.Phase := PHASE_THRESHOLD;
         end if;
      end if;
   end Apply_Pulse;

end Pulse_Entities;
