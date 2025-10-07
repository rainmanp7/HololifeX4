-- emergeos.ads - HoloXlife OS Package Specification
package EmergeOS is
   pragma Elaborate_Body;  -- Ensure body is elaborated before use
   
   procedure EmergeOS;
   pragma Export (C, EmergeOS, "_ada_boot");
   -- Main operating system procedure exported for C linkage
   
end EmergeOS;
