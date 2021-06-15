defmodule Rs2ex.Location do
  use Bitwise

  @enforce_keys [:x, :y, :z]

  defstruct [:x, :y, :z]

  def local_coordinates(%__MODULE__{x: x, y: y} = location) do
    {region_x, region_y} = region_coordinates(location)
    {x - 8 * region_x, y - 8 * region_y}
  end

  def region_coordinates(%__MODULE__{x: x, y: y}) do
    {(x >>> 3) - 6, (y >>> 3) - 6}
  end

  def transform(%__MODULE__{x: x, y: y, z: z} = location, x_offset, y_offset, z_offset) do
    %__MODULE__{location | x: x + x_offset, y: y + y_offset, z: z + z_offset}
  end

  def same?(%__MODULE__{} = a, %__MODULE__{} = b) do
    a.x == b.x && a.y == b.y && a.z == b.z
  end

  def within_distance?(%__MODULE__{} = a, %__MODULE__{} = b) do
    if a.z == b.z do
      {delta_x, delta_y} = {b.x - a.x, b.y - a.y}
      Enum.member?(-15..14, delta_x) && Enum.member?(-15..14, delta_y)
    else
      false
    end
  end

  def within_interaction_distance?(%__MODULE__{} = a, %__MODULE__{} = b) do
    if a.z == b.z do
      {delta_x, delta_y} = {b.x - a.x, b.y - a.y}
      Enum.member?(-3..2, delta_x) && Enum.member?(-3..2, delta_y)
    else
      false
    end
  end
end

defimpl Inspect, for: Rs2ex.Location do
  def inspect(%Rs2ex.Location{x: x, y: y, z: z}, _opts) do
    "[#{x}, #{y}, #{z}]"
  end
end
