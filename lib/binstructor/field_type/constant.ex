defmodule Binstructor.FieldType.Constant do
  defstruct value: nil

  defmacro constant(value) do
    field = quote do
      field = %Binstructor.FieldType.Constant{value: unquote(value)}
    end

    Binstructor.FieldType.Util.add_field(field)
  end
end

defimpl Binstructor.Field, for: Binstructor.FieldType.Constant do
  def struct_definition(_field, _module) do
    :undefined
  end

  def struct_match_pattern(_field, _module, _prefix) do
    :undefined
  end

  def struct_build_pattern(_field, _module, _prefix) do
    :undefined
  end

  def bin_match_pattern(%Binstructor.FieldType.Constant{value: value}, _module, _prefix) do
    {:ok, Macro.escape(value)}
  end

  def bin_build_pattern(%Binstructor.FieldType.Constant{value: value}, _module, _prefix) do
    {:ok, Macro.escape(value)}
  end
end
