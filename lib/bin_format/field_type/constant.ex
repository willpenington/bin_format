defmodule BinFormat.FieldType.Constant do
  defstruct value: nil

  defmacro constant(value) do
    field = quote do
      field = %BinFormat.FieldType.Constant{value: unquote(value)}
    end

    BinFormat.FieldType.Util.add_field(field)
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
