-- Base Entity Implementation
package body Pulse_Entities is

   procedure Reset_Phase (Entity : in out Base_Entity) is
   begin
      Entity.Current_Phase := 0;
   end Reset_Phase;

   function Should_Flash (Entity : Base_Entity) return Boolean is
   begin
      return Entity.Current_Phase >= PHASE_THRESHOLD and Entity.Is_Active;
   end Should_Flash;

   procedure Apply_Pulse (Entity : in out Base_Entity; Sender_ID : Entity_ID) is
      Phase_Boost : Phase_Type;
   begin
      if Entity.Current_Phase < PHASE_THRESHOLD and Entity.Is_Active then
         -- Core sync rule: phase boost proportional to current phase
         Phase_Boost := (Entity.Current_Phase * Entity.Coupling_Str) / 100;
         Entity.Current_Phase := Entity.Current_Phase + Phase_Boost;
         
         -- Cap at threshold
         if Entity.Current_Phase > PHASE_THRESHOLD then
            Entity.Current_Phase := PHASE_THRESHOLD;
         end if;
      end if;
   end Apply_Pulse;

end Pulse_Entities;