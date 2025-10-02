-- emergeos.ads: Pure Ada OS Kernel Specification
package EmergeOS is
   pragma Elaborate_Body;
   
   -- Entity types for core OS management
   type Entity_Type is (Entity_CPU, Entity_Memory, Entity_Device, Entity_Filesystem);
   type Entity_Status is (Active);
   
   type Entity_Record is record
      Kind : Entity_Type;
      ID : Natural;
      Status : Entity_Status;
      Priority : Natural;
      Memory_Base : Natural;
   end record;
   
   -- Core OS procedures
   procedure EmergeOS;
   function Create_Entity (E_Type : Entity_Type) return Natural;
   
end EmergeOS;
