package UART is
   procedure Initialize;
   procedure Put_Char(C : Character);
   procedure Put_String(S : String);
   procedure Put_Line(S : String);
   function Get_Char return Character;
   function Data_Available return Boolean;
end UART;