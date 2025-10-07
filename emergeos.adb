-- emergeos.adb: Ultra Simple Boot Test
with System;

package body EmergeOS is
   procedure Boot is
      -- Ultra simple - just VGA, no serial
      type VGA_Buffer is array (0 .. 79) of Character;
      VGA_Chars : VGA_Buffer;
      for VGA_Chars'Address use System'To_Address(16#B8000#);
      pragma Import (Ada, VGA_Chars);
      
      VGA_Attrs : VGA_Buffer;
      for VGA_Attrs'Address use System'To_Address(16#B8001#);
      pragma Import (Ada, VGA_Attrs);
      
   begin
      -- Write "ADA BOOT" to VGA
      VGA_Chars(0) := 'A';
      VGA_Attrs(0) := Character'Val(15);
      VGA_Chars(1) := 'D';
      VGA_Attrs(1) := Character'Val(15);
      VGA_Chars(2) := 'A';
      VGA_Attrs(2) := Character'Val(15);
      VGA_Chars(3) := ' ';
      VGA_Attrs(3) := Character'Val(15);
      VGA_Chars(4) := 'B';
      VGA_Attrs(4) := Character'Val(15);
      VGA_Chars(5) := 'O';
      VGA_Attrs(5) := Character'Val(15);
      VGA_Chars(6) := 'O';
      VGA_Attrs(6) := Character'Val(15);
      VGA_Chars(7) := 'T';
      VGA_Attrs(7) := Character'Val(15);
      VGA_Chars(8) := '!';
      VGA_Attrs(8) := Character'Val(15);
      
      -- Hang forever
      loop
         null;
      end loop;
   end Boot;
end EmergeOS;
