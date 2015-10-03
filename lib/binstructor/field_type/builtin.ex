defmodule Binstructor.FieldType.BuiltIn do
  defstruct type: nil, name: nil, default: nil, size: nil, options: []


end

defimpl Binstructor.Field, for: Binstructor.FieldType.BuiltIn do

  alias Binstructor.FieldType.BuiltIn, as: BuiltIn

  defp struct_def(%BuiltIn{name: name, default: default}, _module) do
    Binstructor.FieldType.Util.standard_struct_def(name, default)
  end

  defp struct_pattern(%BuiltIn{name: name}, module, prefix) do
    Binstructor.FieldType.Util.standard_struct_pattern(name, module, prefix)
  end 

  defp bin_pattern(%BuiltIn{name: name, type: type, size: size, options: options}, module, prefix) do
    Binstructor.FieldType.Util.standard_bin_pattern(name, type, size, 
                                                    options, module, prefix)
  end

  def struct_definition(field, module) do
    struct_def(field, module)
  end

  def struct_build_pattern(field, module, prefix) do
    struct_pattern(field, module, prefix)
  end

  def struct_match_pattern(field, module, prefix) do
    struct_pattern(field, module, prefix)
  end

  def bin_build_pattern(field, module, prefix) do
    bin_pattern(field, module, prefix)
  end

  def bin_match_pattern(field, module, prefix) do
    bin_pattern(field, module, prefix)
  end
end
