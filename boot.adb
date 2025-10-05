-- boot.adb: Pure Ada Bootloader - PROTOCOL-VERIFIED MEMORY MAPPING
with System.Storage_Elements;
with EmergeOS;

procedure Boot is
   type Byte is mod 2**8;

   -- VGA memory mapping (PROTOCOL: Use proven C→Ada pattern)
   type VGA_Entry is record
      Char : Character;
      Attr : Byte;
   end record;
   pragma Pack (VGA_Entry);

   type VGA_Buffer_Type is array (0 .. 24, 0 .. 79) of VGA_Entry;
   
   VGA_Buffer : VGA_Buffer_Type;
   for VGA_Buffer'Address use System.Storage_Elements.To_Address(16#B8000#);
   pragma Import (Ada, VGA_Buffer);
   pragma Volatile (VGA_Buffer);
   
   Console_Row : Natural := 0;
   Console_Col : Natural := 0;

   -- PROTOCOL: Immediate VGA test using memory mapping
   procedure Immediate_VGA_Test is
   begin
      -- Direct memory write using proven pattern (no assembly)
      VGA_Buffer(0, 0) := ('H', 16#0F#);
      VGA_Buffer(0, 1) := ('Y', 16#0F#);
      VGA_Buffer(0, 2) := ('P', 16#0F#);
      VGA_Buffer(0, 3) := ('E', 16#0F#);
      VGA_Buffer(0, 4) := ('R', 16#0F#);
   end Immediate_VGA_Test;

   -- PROTOCOL: Simplified console using memory mapping
   procedure Console_Clear is
      Color : constant Byte := 16#0F#; -- White on black
   begin
      for Row in VGA_Buffer'Range(1) loop
         for Col in VGA_Buffer'Range(2) loop
            VGA_Buffer(Row, Col) := (' ', Color);
         end loop;
      end loop;
      Console_Row := 0;
      Console_Col := 0;
   end Console_Clear;

   procedure Console_Put_Char (C : Character) is
      Color : constant Byte := 16#0F#; -- White on black
   begin
      if C = ASCII.LF then
         Console_Col := 0;
         if Console_Row < 24 then
            Console_Row := Console_Row + 1;
         end if;
      elsif C = ASCII.CR then
         Console_Col := 0;
      else
         if Console_Row < 25 and Console_Col < 80 then
            VGA_Buffer(Console_Row, Console_Col) := (C, Color);
            Console_Col := Console_Col + 1;
            if Console_Col >= 80 then
               Console_Col := 0;
               if Console_Row < 24 then
                  Console_Row := Console_Row + 1;
               end if;
            end if;
         end if;
      end if;
   end Console_Put_Char;

   procedure Console_Put_String (S : String) is
   begin
      for I in S'Range loop
         Console_Put_Char(S(I));
      end loop;
   end Console_Put_String;

   procedure Console_New_Line is
   begin
      Console_Put_Char(ASCII.LF);
   end Console_New_Line;

begin
   -- PROTOCOL: Immediate VGA output using proven memory mapping
   Immediate_VGA_Test;

   -- PROTOCOL: Preserve all working systems (unchanged)
   Console_Clear;
   Console_Put_String("HoloXlife OS v1.0 - Pure Ada Implementation");
   Console_New_Line;
   Console_Put_String("Bootloader: VGA OUTPUT WORKING!");
   Console_New_Line;
   Console_Put_String("System: Starting kernel...");
   Console_New_Line;

   -- PROTOCOL: Maintain entity system call
   EmergeOS.EmergeOS;

   Console_Put_String("System: Kernel returned - halting");
   Console_New_Line;

   loop
      null;
   end loop;
end Boot;
