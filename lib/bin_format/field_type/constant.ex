defmodule BinFormat.FieldType.Constant do
  defstruct value: nil

  @moduledoc """
  Constant field type for defformat
  """

  @doc """
  Add a constant field to the format structure in defformat.

  Adds a field to the format structure that requires a specific value in the
  binary for the decode function to be sucessful. If the value found does not
  match what is expected the function will fail with a BadMatch error.
  
  The value supplied will always be emmited when encoding the value.
  
  No field will be defined in the struct for the format.
  """
  defmacro constant(value) do
    field = quote do
      field = %BinFormat.FieldType.Constant{value: unquote(value)}
    end
    
    quote do
      BinFormat.FieldType.Util.add_field(unquote(field), __ENV__)
    end
  end
end

defimpl BinFormat.Field, for: BinFormat.FieldType.Constant do
  def struct_definition(_field, _module) do
    :undefined
  end

  def struct_match_pattern(_field, _module, _prefix) do
    :undefined
  end

  def struct_build_pattern(_field, _module, _prefix) do
    :undefined
  end

  def bin_match_pattern(%BinFormat.FieldType.Constant{value: value}, _module, _prefix) do
    {:ok, Macro.escape(value)}
  end

  def bin_build_pattern(%BinFormat.FieldType.Constant{value: value}, _module, _prefix) do
    {:ok, Macro.escape(value)}
  end
end
