-- holographic_memory.adb - Holographic Memory Implementation
with Holographic_Vectors;

package body Holographic_Memory is

   procedure Initialize is
   begin
      Holographic_System_State.Memory_Count := 0;
      Holographic_System_State.Global_Timestamp := 0;
      
      for I in Holographic_System_State.Memory_Pool'Range loop
         Holographic_System_State.Memory_Pool(I).Valid := False;
      end loop;
   end Initialize;

   procedure Encode_Memory(Input, Output : Holographic_Vector) is
   begin
      -- Evict oldest entry if memory is full (from C kernel logic)
      if Holographic_System_State.Memory_Count >= MAX_MEMORY_ENTRIES then
         for I in 1 .. MAX_MEMORY_ENTRIES - 1 loop
            Holographic_System_State.Memory_Pool(I) := 
              Holographic_System_State.Memory_Pool(I + 1);
         end loop;
         Holographic_System_State.Memory_Count := MAX_MEMORY_ENTRIES - 1;
      end if;
      
      -- Add new entry
      declare
         Entry_Index : constant Natural := Holographic_System_State.Memory_Count + 1;
      begin
         Holographic_System_State.Memory_Pool(Entry_Index) := 
           (Input_Pattern  => Input,
            Output_Pattern => Output,
            Timestamp      => Holographic_System_State.Global_Timestamp,
            Valid          => True);
         
         Holographic_System_State.Memory_Count := Entry_Index;
         Holographic_System_State.Global_Timestamp := 
           Holographic_System_State.Global_Timestamp + 1;
      end;
   end Encode_Memory;

   function Retrieve_Memory(Hash : DWord) return Holographic_Vector is
   begin
      -- Search from most recent to oldest (from C kernel logic)
      for I in reverse 1 .. Holographic_System_State.Memory_Count loop
         if Holographic_System_State.Memory_Pool(I).Valid and then
            Holographic_System_State.Memory_Pool(I).Input_Pattern.Hash_Signature = Hash
         then
            return Holographic_System_State.Memory_Pool(I).Output_Pattern;
         end if;
      end loop;
      
      return Holographic_Vectors.Null_Vector;
   end Retrieve_Memory;

   procedure Load_Initial_Genome_Vocabulary is
      Vocabulary : constant array (1 .. 11) of String(1..20) := (
         "ACTION_PRODUCE        ",
         "ACTION_CONSUME       ",
         "ACTION_SHARE         ",
         "ACTION_ACTIVATE      ",
         "ACTION_DEACTIVATE    ",
         "TRAIT_GENERIC        ",
         "TRAIT_ACTIVE         ",
         "TRAIT_DORMANT        ",
         "SENSOR_NEIGHBOR_ACTIVE",
         "SENSOR_MEMORY_MATCH  ",
         "GENOME_SIMPLE_RULE_1 "
      );
   begin
      for I in Vocabulary'Range loop
         declare
            Pattern : constant Holographic_Vector := 
              Holographic_Vectors.Create_Vector(Vocabulary(I));
         begin
            Encode_Memory(Pattern, Pattern);
         end;
      end loop;
   end Load_Initial_Genome_Vocabulary;

end Holographic_Memory;