-- temporal_entity.ads: Temporal Foresight Entity - UNIFIED TYPE SYSTEM
-- Second specialized pulse-coupled entity for HelloXLife OS
with Pulse_Types; use Pulse_Types;

package Temporal_Entity is
   
   type Temporal_Anchor is record
      Base : Pulse_Types.Entity_Record;  -- Now uses unified type
      Boot_Time_Reference : Natural;
      Cycle_Optimizations : Natural;
      Lifecycle_Phase : Natural;
      Timing_Insights_Generated : Natural;
   end record;
   
   -- Entity lifecycle procedures
   procedure Initialize (Entity : in out Temporal_Anchor);
   procedure Evolve_Phase (Entity : in out Temporal_Anchor);
   function Check_Flash (Entity : Temporal_Anchor) return Boolean;
   procedure Receive_Pulse (Entity : in out Temporal_Anchor; Sender_ID : Entity_ID);
   
   -- Temporal-specific functions
   function Calculate_System_Timing return Natural;
   function Analyze_Lifecycle_Patterns return Natural;
   function Generate_Timing_Optimization return Natural;
   
   -- Entity constants
   TEMPORAL_FREQUENCY : constant Frequency_Type := 6;  -- Faster cognitive processing
   TEMPORAL_COUPLING  : constant Coupling_Type := 9;   -- Strong influence on network
   
end Temporal_Entity;
