-- holographic_memory.ads - Holographic Memory Encoding & Retrieval
with Types;
with Holographic_Vectors;

package Holographic_Memory is
   pragma Preelaborate;
   
   use Types;
   use Holographic_Vectors;
   
   -- Memory entry (from C kernel)
   type Memory_Entry is record
      Input_Pattern  : Holographic_Vector;
      Output_Pattern : Holographic_Vector;
      Timestamp      : DWord;
      Valid          : Boolean;
   end record;
   
   -- Memory pool (from C kernel)
   type Memory_Pool_Type is array (1 .. MAX_MEMORY_ENTRIES) of Memory_Entry;
   
   -- Holographic system state (from C kernel)
   type Holographic_System is record
      Memory_Pool      : Memory_Pool_Type;
      Memory_Count     : Natural;
      Global_Timestamp : DWord;
   end record;
   
   -- System operations
   procedure Initialize;
   procedure Encode_Memory(Input, Output : Holographic_Vector);
   function Retrieve_Memory(Hash : DWord) return Holographic_Vector;
   procedure Load_Initial_Genome_Vocabulary;
   
   -- Global system instance
   Holographic_System_State : Holographic_System;
   
end Holographic_Memory;