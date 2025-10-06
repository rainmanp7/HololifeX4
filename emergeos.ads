-- emergeos.ads - HoloXlife OS Package Specification
package EmergeOS is
   pragma Elaborate_Body;
   
   procedure EmergeOS;
   pragma Export (C, EmergeOS, "_ada_boot");  -- CRITICAL: This must exist
   
end EmergeOS;
