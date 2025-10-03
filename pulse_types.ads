-- Pulse-Coupled Oscillator Core Types - Phase 1 Foundation
package Pulse_Types is
   pragma Pure;
   
   -- Core oscillator parameters (fixed-point for bare metal)
   type Phase_Type is new Natural range 0 .. 1000;  -- [0.0, 1.0] as 0-1000
   type Frequency_Type is new Natural range 1 .. 10; -- Natural frequency
   type Coupling_Type is new Natural range 0 .. 50;  -- Coupling strength (0.00 to 0.50)
   
   -- Entity identification
   type Entity_ID is (
      ENTITY_HARDWARE,
      ENTITY_TEMPORAL, 
      ENTITY_BUILD,
      ENTITY_SEMANTIC,
      ENTITY_MATH,
      ENTITY_INTENTIONAL
   );
   
   -- Insight types (DECLARE THIS FIRST)
   type Insight_Type is (INSIGHT_NONE, INSIGHT_VALIDATION, INSIGHT_OPTIMIZATION, INSIGHT_PREDICTION);
   
   -- Network constants
   MAX_ENTITIES : constant := 6;
   PHASE_THRESHOLD : constant Phase_Type := 1000;  -- 1.0 threshold
   DEFAULT_COUPLING : constant Coupling_Type := 10; -- 0.10 coupling
   TIME_STEP : constant := 5;  -- Phase evolution step
   
   -- Entity record
   type Entity_Record is record
      ID : Entity_ID;
      Phase : Phase_Type;
      Frequency : Frequency_Type;
      Coupling : Coupling_Type;
      Flash_Count : Natural;
      Is_Active : Boolean;
   end record;
   
   -- Network array
   type Entity_Array is array (1 .. MAX_ENTITIES) of Entity_Record;
   
   -- Insight record (NOW Insight_Type IS FULLY DECLARED)
   type Insight_Record is record
      Insight_Type : Insight_Type;
      Source_Entity : Entity_ID;
      Message : String (1 .. 80);
      Phase_At_Flash : Phase_Type;
   end record;
   
end Pulse_Types;
