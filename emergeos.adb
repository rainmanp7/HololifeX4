-- emergeos.adb: Minimal Boot + Serial Test
with System;
with System.Storage_Elements;

package body EmergeOS is
   procedure Boot is
      -- Minimal VGA setup only
      type VGA_Entry is record
         Char : Character;
         Attr : Character;
      end record;
      pragma Pack (VGA_Entry);
      
      type VGA_Buffer is array (0 .. 24, 0 .. 79) of VGA_Entry;
      VGA : VGA_Buffer;
      for VGA'Address use 16#B8000#;
      pragma Import (Ada, VGA);
      
      -- Simple UART functions (inline)
      procedure Serial_Init is
      begin
         -- Initialize COM1 (0x3F8)
         System.Machine_Code.Asm ("mov dx, 16#3F9#", Volatile => True);
         System.Machine_Code.Asm ("mov al, 0", Volatile => True);
         System.Machine_Code.Asm ("out dx, al", Volatile => True);
         
         System.Machine_Code.Asm ("mov dx, 16#3FB#", Volatile => True);
         System.Machine_Code.Asm ("mov al, 16#80#", Volatile => True);
         System.Machine_Code.Asm ("out dx, al", Volatile => True);
         
         System.Machine_Code.Asm ("mov dx, 16#3F8#", Volatile => True);
         System.Machine_Code.Asm ("mov al, 3", Volatile => True);
         System.Machine_Code.Asm ("out dx, al", Volatile => True);
         
         System.Machine_Code.Asm ("mov dx, 16#3F9#", Volatile => True);
         System.Machine_Code.Asm ("mov al, 0", Volatile => True);
         System.Machine_Code.Asm ("out dx, al", Volatile => True);
         
         System.Machine_Code.Asm ("mov dx, 16#3FB#", Volatile => True);
         System.Machine_Code.Asm ("mov al, 3", Volatile => True);
         System.Machine_Code.Asm ("out dx, al", Volatile => True);
         
         System.Machine_Code.Asm ("mov dx, 16#3FC#", Volatile => True);
         System.Machine_Code.Asm ("mov al, 16#C7#", Volatile => True);
         System.Machine_Code.Asm ("out dx, al", Volatile => True);
      end Serial_Init;
      
      procedure Serial_Put_Char (C : Character) is
      begin
         -- Wait for transmit buffer empty
         loop
            System.Machine_Code.Asm ("mov dx, 16#3FD#", Volatile => True);
            System.Machine_Code.Asm ("in al, dx", Volatile => True);
            System.Machine_Code.Asm ("test al, 16#20#", Volatile => True);
            exit when System.Machine_Code.Asm ("jnz $+2", Volatile => True);
         end loop;
         
         -- Send character
         System.Machine_Code.Asm ("mov dx, 16#3F8#", Volatile => True);
         System.Machine_Code.Asm ("mov al, %0",
           Inputs => (Character'Asm_Input ("r", C)),
           Volatile => True);
         System.Machine_Code.Asm ("out dx, al", Volatile => True);
      end Serial_Put_Char;
      
      procedure Serial_Put_String (S : String) is
      begin
         for I in S'Range loop
            Serial_Put_Char (S(I));
         end loop;
      end Serial_Put_String;
      
   begin
      -- Initialize serial first
      Serial_Init;
      Serial_Put_String("SERIAL: OK - Ada Kernel Booted!");
      Serial_Put_Char(ASCII.LF);
      Serial_Put_Char(ASCII.CR);
      
      -- Simple VGA output
      VGA(0, 0) := ('A', Character'Val(15));
      VGA(0, 1) := ('D', Character'Val(15));
      VGA(0, 2) := ('A', Character'Val(15));
      VGA(0, 3) := (' ', Character'Val(15));
      VGA(0, 4) := ('B', Character'Val(15));
      VGA(0, 5) := ('O', Character'Val(15));
      VGA(0, 6) := ('O', Character'Val(15));
      VGA(0, 7) := ('T', Character'Val(15));
      VGA(0, 8) := ('!', Character'Val(15));
      
      Serial_Put_String("VGA: OK - Displaying ADA BOOT!");
      Serial_Put_Char(ASCII.LF);
      Serial_Put_Char(ASCII.CR);
      Serial_Put_String("MINIMAL KERNEL: SUCCESS - Ready for restore");
      Serial_Put_Char(ASCII.LF);
      Serial_Put_Char(ASCII.CR);
      
      -- Hang forever
      loop
         null;
      end loop;
   end Boot;
end EmergeOS;
