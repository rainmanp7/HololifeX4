package body Operations is
   procedure Transform_Coordinate (X, Y, Z : in out Integer) is
   begin
      X := X + 1;
      Y := Y - 1;
      Z := Z * 2;
   end Transform_Coordinate;
end Operations;
