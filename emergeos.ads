-- emergeos.ads - Minimal Boot Test
package EmergeOS is
   procedure Boot;
   pragma Export (C, Boot, "_ada_boot");
end EmergeOS;
