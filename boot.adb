-- boot.adb - Pure Ada Bootloader (No Inline Assembly Version)
with System.Storage_Elements;
with EmergeOS;

procedure Boot is
   -- REMOVED: use System.Storage_Elements;

   -- Basic types for OS development - ONLY what we use
   type Byte is mod 2**8;

   -- VGA CONSOLE SUBSYSTEM (Pure Ada)
   type VGA_Color is
     (Black, Blue, Green, Cyan, Red, Magenta, Brown, Light_Gray,
      Dark_Gray, Light_Blue, Light_Green, Light_Cyan, Light_Red,
      Light_Magenta, Yellow, White);
   
   for VGA_Color use
     (Black => 0, Blue => 1, Green => 2, Cyan => 3, Red => 4,
      Magenta => 5, Brown => 6, Light_Gray => 7, Dark_Gray => 8,
      Light_Blue => 9, Light_Green => 10, Light_Cyan => 11,
      Light_Red => 12, Light_Magenta => 13, Yellow => 14, White => 15);

   type VGA_Entry is record
      Char : Character;
      Attr : Byte;
   end record;
   pragma Pack (VGA_Entry);

   type VGA_Buffer_Type is array (0 .. 24, 0 .. 79) of VGA_Entry;

   VGA_Buffer : VGA_Buffer_Type;
   for VGA_Buffer'Address use System.Storage_Elements.To_Address(16#B8000#);
   pragma Import (Ada, VGA_Buffer);

   Console_Row : Natural := 0;
   Console_Col : Natural := 0;

   -- ... rest of the file remains exactly the same ...
