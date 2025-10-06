-- uart_driver.adb: Professional UART driver implementation
with System.Machine_Code; use System.Machine_Code;

package body UART_Driver is

   type Byte is mod 2**8;
   
   -- Hardware constants
   COM1_BASE : constant := 16#3F8#;
   COM2_BASE : constant := 16#2F8#;
   COM3_BASE : constant := 16#3E8#;
   COM4_BASE : constant := 16#2E8#;

   -- Register offsets
   DATA_REG          : constant := 0;
   INT_ENABLE_REG    : constant := 1;
   FIFO_CTRL_REG     : constant := 2;
   LINE_CTRL_REG     : constant := 3;
   MODEM_CTRL_REG    : constant := 4;
   LINE_STATUS_REG   : constant := 5;
   MODEM_STATUS_REG  : constant := 6;
   SCRATCH_REG       : constant := 7;

   -- Line Status Register bits
   LSR_DATA_READY           : constant Byte := 2#0000_0001#;
   LSR_OVERRUN_ERROR        : constant Byte := 2#0000_0010#;
   LSR_PARITY_ERROR         : constant Byte := 2#0000_0100#;
   LSR_FRAMING_ERROR        : constant Byte := 2#0000_1000#;
   LSR_BREAK_INTERRUPT      : constant Byte := 2#0001_0000#;
   LSR_TX_HOLDING_EMPTY     : constant Byte := 2#0010_0000#;
   LSR_TX_EMPTY             : constant Byte := 2#0100_0000#;
   LSR_FIFO_ERROR           : constant Byte := 2#1000_0000#;

   -- Line Control Register bits
   LCR_DLAB                 : constant Byte := 2#1000_0000#;
   LCR_SET_BREAK            : constant Byte := 2#0100_0000#;
   LCR_STICK_PARITY         : constant Byte := 2#0010_0000#;
   LCR_EVEN_PARITY          : constant Byte := 2#0001_0000#;
   LCR_ENABLE_PARITY        : constant Byte := 2#0000_1000#;

   -- FIFO Control Register bits
   FCR_ENABLE_FIFO          : constant Byte := 2#0000_0001#;
   FCR_CLEAR_RX             : constant Byte := 2#0000_0010#;
   FCR_CLEAR_TX             : constant Byte := 2#0000_0100#;
   FCR_DMA_MODE             : constant Byte := 2#0000_1000#;
   FCR_TRIGGER_14           : constant Byte := 2#1100_0000#;

   -- Modem Control Register bits
   MCR_DTR                  : constant Byte := 2#0000_0001#;
   MCR_RTS                  : constant Byte := 2#0000_0010#;
   MCR_OUT1                 : constant Byte := 2#0000_0100#;
   MCR_OUT2                 : constant Byte := 2#0000_1000#;
   MCR_LOOPBACK             : constant Byte := 2#0001_0000#;

   -- Port state tracking
   type Port_State is record
      Base_Address  : Natural;
      Initialized   : Boolean := False;
      Last_Error    : UART_Error := No_Error;
   end record;

   Port_States : array (UART_Port) of Port_State := (
      COM1 => (COM1_BASE, False, No_Error),
      COM2 => (COM2_BASE, False, No_Error),
      COM3 => (COM3_BASE, False, No_Error),
      COM4 => (COM4_BASE, False, No_Error)
   );

   -- Low-level I/O operations
   procedure Out_Byte (Port_Addr : Natural; Value : Byte) is
   begin
      Asm ("outb %0, %1",
           Inputs => (
              Byte'Asm_Input ("a", Value),
              System.Address'Asm_Input ("Nd", System'To_Address(Port_Addr))
           ),
           Volatile => True);
   end Out_Byte;

   function In_Byte (Port_Addr : Natural) return Byte is
      Result : Byte;
   begin
      Asm ("inb %1, %0",
           Outputs => Byte'Asm_Output ("=a", Result),
           Inputs => System.Address'Asm_Input ("Nd", System'To_Address(Port_Addr)),
           Volatile => True);
      return Result;
   end In_Byte;

   -- Implementation continues... (same professional implementation as before)
   -- [Rest of the implementation code...]
   
end UART_Driver;