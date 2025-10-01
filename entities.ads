-- entities.ads - Enhanced Entity System with Evolution
with Types;
with Holographic_Vectors;

package Entities is
   pragma Preelaborate;
   
   use Types;
   use Holographic_Vectors;
   
   -- Enhanced entity record (from C kernel)
   type Entity_Record is record
      ID                   : Natural;
      State                : Holographic_Vector;
      Genome               : access Holographic_Vector;
      Age                  : DWord;
      Interaction_Count    : DWord;
      Is_Active            : Boolean;
      
      -- Specialization and evolution
      Specialization_Scores : array (Entity_Domain_Index) of Float;
      Resource_Allocation   : Float;
      Confidence           : Float;
      Domain_Name          : String(1..32);
      
      -- Task and evolution (from C kernel)
      Task_Vector          : Holographic_Vector;
      Path_ID              : DWord;
      Task_Alignment       : Float;
      Fitness_Score        : DWord;
      Spawn_Count          : DWord;
      Marked_For_GC        : Boolean;
      Is_Mutant            : Boolean;
   end record;
   
   -- Entity pool
   type Entity_Pool_Type is array (1 .. MAX_ENTITIES) of Entity_Record;
   
   -- Entity operations
   procedure Initialize_Entities;
   function Spawn_Entity return Natural;
   procedure Update_Entities;
   procedure Render_Entities_To_VGA;
   
   -- Global entity state
   Entity_Pool         : Entity_Pool_Type;
   Active_Entity_Count : Natural;
   
end Entities;