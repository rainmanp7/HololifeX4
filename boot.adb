-- boot.adb: Pure Ada Bootloader - FIXED VGA OUTPUT
with System.Storage_Elements;
with System.Machine_Code;
with EmergeOS;

procedure Boot is
   type Byte is mod 2**8;

   -- VGA memory address
   VGA_MEMORY : constant := 16#B8000#;

   Console_Row : Natural := 0;
   Console_Col : Natural := 0;

   -- IMMEDIATE VGA TEST PATTERN - FIRST EXECUTION
   procedure Immediate_VGA_Test is
   begin
      -- Write test pattern directly to VGA memory (0xB8000)
      -- Same pattern as C system: 'H','Y','P','E','R'
      System.Machine_Code.Asm(
        "movl $$0xB8000, %edi" & ASCII.LF &
        "movb $$'H', (%edi)" & ASCII.LF &
        "movb $$0x0F, 1(%edi)" & ASCII.LF &
        "movb $$'Y', 2(%edi)" & ASCII.LF &
        "movb $$0x0F, 3(%edi)" & ASCII.LF &
        "movb $$'P', 4(%edi)" & ASCII.LF &
        "movb $$0x0F, 5(%edi)" & ASCII.LF &
        "movb $$'E', 6(%edi)" & ASCII.LF &
        "movb $$0x0F, 7(%edi)" & ASCII.LF &
        "movb $$'R', 8(%edi)" & ASCII.LF &
        "movb $$0x0F, 9(%edi)",
        Volatile => True
      );
   end Immediate_VGA_Test;

   -- DIRECT MEMORY ACCESS - No pragma Import
   procedure Write_To_VGA (Row, Col : Natural; Char : Character; Attr : Byte) is
   begin
      -- Calculate position in VGA buffer
      declare
         Position : constant Natural := Row * 80 + Col;
         VGA_Ptr : System.Address := 
           System.Storage_Elements.To_Address(VGA_MEMORY + Position * 2);
      begin
         -- Write character directly to memory
         System.Machine_Code.Asm(
           "movb %0, (%1)" & ASCII.LF &
           "movb %2, 1(%1)",
           Inputs => (
             Byte'Asm_Input("r", Character'Pos(Char)),
             System.Address'Asm_Input("r", VGA_Ptr),
             Byte'Asm_Input("r", Attr)
           ),
           Volatile => True
         );
      end;
   end Write_To_VGA;

   function Make_Color (FG, BG : Natural) return Byte is
   begin
      return Byte(FG) or (Byte(BG) * 16);
   end Make_Color;

   procedure Console_Clear is
      Color : constant Byte := Make_Color(15, 0); -- White on black
   begin
      for Row in 0 .. 24 loop
         for Col in 0 .. 79 loop
            Write_To_VGA(Row, Col, ' ', Color);
         end loop;
      end loop;
      Console_Row := 0;
      Console_Col := 0;
   end Console_Clear;

   procedure Console_Put_Char (C : Character) is
      Color : constant Byte := Make_Color(15, 0); -- White on black
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
            Write_To_VGA(Console_Row, Console_Col, C, Color);
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
   -- IMMEDIATE VGA TEST - FIRST INSTRUCTION (VIDEO FIX)
   Immediate_VGA_Test;

   -- THEN PROCEED WITH EXISTING CODE (UNCHANGED)
   Console_Clear;
   Console_Put_String("HoloXlife OS v1.0 - Pure Ada Implementation");
   Console_New_Line;
   Console_Put_String("Bootloader: VGA OUTPUT WORKING!");
   Console_New_Line;
   Console_Put_String("System: Starting kernel...");
   Console_New_Line;

   -- Call the main kernel procedure
   EmergeOS.EmergeOS;

   -- If kernel returns, halt
   Console_Put_String("System: Kernel returned - halting");
   Console_New_Line;

   loop
      null;
   end loop;
end Boot;
