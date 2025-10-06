-- uart_driver.ads: Professional UART driver specification
with System;

package UART_Driver is
   pragma Preelaborate;

   -- Configuration types
   type Baud_Rate is (Baud_9600, Baud_19200, Baud_38400, Baud_57600, Baud_115200);
   type Data_Bits is (Bits_5, Bits_6, Bits_7, Bits_8);
   type Parity_Mode is (None, Odd, Even, Mark, Space);
   type Stop_Bits is (One, Two);
   type UART_Error is (No_Error, Overrun_Error, Parity_Error, Framing_Error, Break_Interrupt, FIFO_Error, Timeout_Error);
   type UART_Port is (COM1, COM2, COM3, COM4);

   type UART_Config is record
      Baud        : Baud_Rate;
      Data        : Data_Bits;
      Parity      : Parity_Mode;
      Stop        : Stop_Bits;
      Enable_FIFO : Boolean;
      RTS_CTS     : Boolean;
   end record;

   Default_Config : constant UART_Config;

   -- Core UART operations
   procedure Initialize (Port : UART_Port; Config : UART_Config := Default_Config);
   function Is_Initialized (Port : UART_Port) return Boolean;
   
   -- Transmit operations
   procedure Put_Char (Port : UART_Port; C : Character);
   procedure Put_String (Port : UART_Port; S : String);
   procedure Put_Line (Port : UART_Port; S : String);
   procedure Put_Hex_Byte (Port : UART_Port; Value : Natural);
   procedure Put_Natural (Port : UART_Port; N : Natural);

   -- Receive operations
   function Get_Char (Port : UART_Port) return Character;
   function Get_Char_Timeout (Port : UART_Port; Timeout : Natural) return Character;
   function Data_Available (Port : UART_Port) return Boolean;
   
   -- Status and error handling
   function TX_Ready (Port : UART_Port) return Boolean;
   function TX_Empty (Port : UART_Port) return Boolean;
   function Get_Last_Error (Port : UART_Port) return UART_Error;
   procedure Clear_Errors (Port : UART_Port);
   
   -- Utility operations
   procedure Flush_RX_Buffer (Port : UART_Port);
   procedure Flush_TX_Buffer (Port : UART_Port);
   procedure Self_Test (Port : UART_Port; Success : out Boolean);

private
   Default_Config : constant UART_Config := (
      Baud        => Baud_115200,
      Data        => Bits_8,
      Parity      => None,
      Stop        => One,
      Enable_FIFO => True,
      RTS_CTS     => False
   );

end UART_Driver;