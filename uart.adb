with System.Machine_Code; use System.Machine_Code;
with System.Storage_Elements;

package body UART is
   type Byte is mod 2**8;
   
   -- Simple UART ports
   COM1_DATA    : constant := 16#3F8#;
   COM1_LINE_STATUS : constant := 16#3FD#;
   
   -- Status bits
   DATA_READY : constant Byte := 16#01#;
   TX_EMPTY   : constant Byte := 16#20#;
   
   procedure Initialize is
   begin
      -- Your original simple initialization
      Asm("outb %0, %1", Inputs => (Byte'Asm_Input("a", 16#80#), Integer'Asm_Input("Nd", 16#3FB#)), Volatile => True);
      Asm("outb %0, %1", Inputs => (Byte'Asm_Input("a", 3), Integer'Asm_Input("Nd", COM1_DATA)), Volatile => True);
      Asm("outb %0, %1", Inputs => (Byte'Asm_Input("a", 0), Integer'Asm_Input("Nd", 16#3F9#)), Volatile => True);
      Asm("outb %0, %1", Inputs => (Byte'Asm_Input("a", 16#03#), Integer'Asm_Input("Nd", 16#3FB#)), Volatile => True);
      Asm("outb %0, %1", Inputs => (Byte'Asm_Input("a", 16#C7#), Integer'Asm_Input("Nd", 16#3FA#)), Volatile => True);
      Asm("outb %0, %1", Inputs => (Byte'Asm_Input("a", 16#0B#), Integer'Asm_Input("Nd", 16#3FC#)), Volatile => True);
   end Initialize;
   
   procedure Put_Char(C : Character) is
      Status : Byte;
   begin
      loop
         Asm("inb %1, %0", Outputs => Byte'Asm_Output("=a", Status), Inputs => Integer'Asm_Input("Nd", COM1_LINE_STATUS), Volatile => True);
         exit when (Status and TX_EMPTY) /= 0;
      end loop;
      Asm("outb %0, %1", Inputs => (Byte'Asm_Input("a", Character'Pos(C)), Integer'Asm_Input("Nd", COM1_DATA)), Volatile => True);
   end Put_Char;
   
   procedure Put_String(S : String) is
   begin
      for I in S'Range loop
         Put_Char(S(I));
      end loop;
   end Put_String;
   
   procedure Put_Line(S : String) is
   begin
      Put_String(S);
      Put_Char(ASCII.CR);
      Put_Char(ASCII.LF);
   end Put_Line;
   
   function Get_Char return Character is
      Status : Byte;
      Data : Byte;
   begin
      loop
         Asm("inb %1, %0", Outputs => Byte'Asm_Output("=a", Status), Inputs => Integer'Asm_Input("Nd", COM1_LINE_STATUS), Volatile => True);
         exit when (Status and DATA_READY) /= 0;
      end loop;
      Asm("inb %1, %0", Outputs => Byte'Asm_Output("=a", Data), Inputs => Integer'Asm_Input("Nd", COM1_DATA), Volatile => True);
      return Character'Val(Data);
   end Get_Char;
   
   function Data_Available return Boolean is
      Status : Byte;
   begin
      Asm("inb %1, %0", Outputs => Byte'Asm_Output("=a", Status), Inputs => Integer'Asm_Input("Nd", COM1_LINE_STATUS), Volatile => True);
      return (Status and DATA_READY) /= 0;
   end Data_Available;
end UART;