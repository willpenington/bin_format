defmodule Binstructor.FieldType.Padding do
  defstruct value: nil

   def binary_match(%__MODULE__{value: val}) when is_binary(val) do
     quote do
       _ :: binary-size(unquote(byte_size(val)))
     end
   end

   def binary_match(%__MODULE__{value: val}) when is_bitstring(val) do
     quote do
       _ :: bitstring-size(unquote(bit_size(val)))
     end
   end

end

defimpl Binstructor.Field, for: Binstructor.FieldType.Padding do
  def struct_definition(_field, _module) do
    :undefined
  end

  def struct_build_pattern(_field, _module, _prefix) do
    :undefined
  end

  def struct_match_pattern(_field, _module, _prefix) do
    :undefined
  end

  def bin_build_pattern(%Binstructor.FieldType.Padding{value: value}, _module, _prefix) do
    {:ok, Macro.escape(value)}
  end

  def bin_match_pattern(field, _module, _prefix) do
    {:ok, Binstructor.FieldType.Padding.binary_match(field)}
  end
end
