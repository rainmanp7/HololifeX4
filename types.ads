-- types.ads - Common type definitions for HoloXlife OS
package Types is
   pragma Pure;
   
   -- Basic numeric types
   type Byte is mod 2**8;
   type DWord is mod 2**32;
   
   -- Holographic system constants
   HOLOGRAPHIC_DIMENSIONS : constant := 512;
   MAX_MEMORY_ENTRIES     : constant := 128;
   MAX_ENTITIES           : constant := 32;
   INITIAL_ENTITIES       : constant := 3;
   MAX_ENTITY_DOMAINS     : constant := 8;
   
   -- Entity domains
   type Entity_Domain_Index is range 1 .. MAX_ENTITY_DOMAINS;
   
end Types;