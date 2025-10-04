-- Synchronization Engine Implementation - TYPE-CORRECTED for Phase 3
package body Pulse_Sync is

   procedure Initialize_Network (Network : in out Sync_Network) is
   begin
      Network.Entity_Count := 0;
      Network.Cycle_Count := 0;
      Network.Coherence_Level := 0;
      Network.Last_Consensus_Cycle := 0;
   end Initialize_Network;

   procedure Add_Entity (Network : in out Sync_Network; Entity : Entity_Record) is
   begin
      if Network.Entity_Count < MAX_ENTITIES then
         Network.Entity_Count := Network.Entity_Count + 1;
         Network.Entities(Network.Entity_Count) := Entity;
      end if;
   end Add_Entity;

   function Calculate_Coherence (Network : Sync_Network) return Natural is
      Total_Phase : Natural := 0;
      Average_Phase : Natural;
   begin
      if Network.Entity_Count = 0 then
         return 0;
      end if;
      
      -- Convert to Natural for arithmetic
      for I in 1 .. Network.Entity_Count loop
         Total_Phase := Total_Phase + Natural(Network.Entities(I).Phase);
      end loop;
      
      Average_Phase := Total_Phase / Network.Entity_Count;
      
      -- Return as percentage
      return (Average_Phase * 100) / Natural(PHASE_THRESHOLD);
   end Calculate_Coherence;

   -- CORRECTED: Get flashing entities with proper signature
   procedure Get_Flashing_Entities(Network : in Sync_Network;
                                  Flashers : out Local_Entity_Array;
                                  Count : out Natural) is
      Temp_Count : Natural := 0;
   begin
      Count := 0;
      
      for I in 1 .. Network.Entity_Count loop
         if Network.Entities(I).Phase >= PHASE_THRESHOLD 
            and Network.Entities(I).Is_Active then
            Temp_Count := Temp_Count + 1;
            if Temp_Count <= Flashers'Length then
               Flashers(Temp_Count) := Network.Entities(I);
            end if;
         end if;
      end loop;
      
      Count := Temp_Count;
   end Get_Flashing_Entities;

   -- CORRECTED: Broadcast pulse to network with firefly coupling
   procedure Broadcast_Pulse(Network : in out Sync_Network;
                           Flashers : in Local_Entity_Array;
                           Count : in Natural) is
      Coupling_Effect : Phase_Type;
   begin
      if Count = 0 then
         return;
      end if;
      
      -- Apply pulse coupling to all non-flashing entities
      for I in 1 .. Network.Entity_Count loop
         if Network.Entities(I).Is_Active 
            and Network.Entities(I).Phase < PHASE_THRESHOLD then
            
            -- Calculate coupling effect based on entity's coupling strength
            Coupling_Effect := Phase_Type(Network.Entities(I).Coupling);
            
            -- Apply phase boost (firefly synchronization)
            Network.Entities(I).Phase := Network.Entities(I).Phase + Coupling_Effect;
            
            -- Cap at threshold
            if Network.Entities(I).Phase > PHASE_THRESHOLD then
               Network.Entities(I).Phase := PHASE_THRESHOLD;
            end if;
         end if;
      end loop;
   end Broadcast_Pulse;

   -- CORRECTED: Process insights from flashing entities
   procedure Process_Insights(Network : in Sync_Network;
                            Flashers : in Local_Entity_Array;
                            Count : in Natural) is
   begin
      -- This is where domain-specific insight processing would occur
      -- For now, we just track that insights were processed
      null; -- Placeholder for Phase 4 enhancement
   end Process_Insights;

   -- CORRECTED: Check for network consensus
   function Check_Consensus (Network : Sync_Network) return Boolean is
      Near_Threshold_Count : Natural := 0;
      Consensus_Threshold : Natural;
   begin
      if Network.Entity_Count = 0 then
         return False;
      end if;
      
      Consensus_Threshold := (Network.Entity_Count * 60) / 100; -- 60%
      
      -- Count entities near flash threshold (phase >= 85%)
      for I in 1 .. Network.Entity_Count loop
         if Network.Entities(I).Is_Active 
            and Network.Entities(I).Phase >= (PHASE_THRESHOLD * 85) / 100 then
            Near_Threshold_Count := Near_Threshold_Count + 1;
         end if;
      end loop;
      
      return Near_Threshold_Count >= Consensus_Threshold;
   end Check_Consensus;

   -- CORRECTED: Calculate phase coherence using Kuramoto order parameter approximation
   function Calculate_Phase_Coherence(Network : Sync_Network) return Natural is
      Total_Phase : Natural := 0;
      Min_Phase, Max_Phase : Phase_Type;
      Phase_Range : Natural;
   begin
      if Network.Entity_Count < 2 then
         return 100; -- Single entity is always coherent
      end if;
      
      -- Find phase range
      Min_Phase := PHASE_THRESHOLD;
      Max_Phase := 0;
      
      for I in 1 .. Network.Entity_Count loop
         if Network.Entities(I).Is_Active then
            if Network.Entities(I).Phase < Min_Phase then
               Min_Phase := Network.Entities(I).Phase;
            end if;
            if Network.Entities(I).Phase > Max_Phase then
               Max_Phase := Network.Entities(I).Phase;
            end if;
         end if;
      end loop;
      
      -- Calculate coherence as inverse of phase spread
      Phase_Range := Natural(Max_Phase - Min_Phase);
      if Phase_Range = 0 then
         return 100; -- Perfect synchrony
      else
         return 100 - (Phase_Range * 100) / Natural(PHASE_THRESHOLD);
      end if;
   end Calculate_Phase_Coherence;

   -- CORRECTED: Reset all entity phases (for refractory periods)
   procedure Reset_Network_Phases(Network : in out Sync_Network) is
   begin
      for I in 1 .. Network.Entity_Count loop
         if Network.Entities(I).Is_Active then
            Network.Entities(I).Phase := 0;
         end if;
      end loop;
   end Reset_Network_Phases;

   -- CORRECTED: Get count of active entities
   function Get_Active_Entity_Count(Network : Sync_Network) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Network.Entity_Count loop
         if Network.Entities(I).Is_Active then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Get_Active_Entity_Count;

end Pulse_Sync;
