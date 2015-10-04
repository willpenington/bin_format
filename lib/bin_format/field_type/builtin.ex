defmodule BinFormat.FieldType.BuiltIn do
  defstruct type: nil, name: nil, default: nil, size: nil, options: []

  defp standard_type(type, name, default, size, options) do
    field = quote do
      %BinFormat.FieldType.BuiltIn{type: unquote(type), name: unquote(name),
        default: unquote(default), size: unquote(size), 
        options: unquote(options)}
    end

    BinFormat.FieldType.Util.add_field(field)
  end
  
  defmacro integer(name, default, size, options \\ []) do
    standard_type(:integer, name, default, size, options)
  end

  defmacro binary(name, default, size, options \\ []) do
    standard_type(:binary, name, default, size, options)
  end 

  defmacro float(name, default, size, options \\ []) do
    standard_type(:float, name, default, size, options)
  end 

  defmacro bits(name, default, size, options \\ []) do
    standard_type(:bits, name, default, size, options)
  end 

  defmacro bitstring(name, default, size, options \\ []) do
    standard_type(:bitstring, name, default, size, options)
  end 

  defmacro bytes(name, default, size, options \\ []) do
    standard_type(:bytes, name, default, size, options)
  end 

  defmacro utf8(name, default, options \\ []) do
    standard_type(:utf8, name, default, :undefined, options)
  end 

  defmacro utf16(name, default, options \\ []) do
    standard_type(:utf16, name, default, :undefined, options)
  end 

  defmacro utf32(name, default, options \\ []) do
    standard_type(:utf32, name, default, :undefined, options)
  end 

end

defimpl BinFormat.Field, for: BinFormat.FieldType.BuiltIn do

  alias BinFormat.FieldType.BuiltIn, as: BuiltIn

  defp struct_def(%BuiltIn{name: name, default: default}, _module) do
    BinFormat.FieldType.Util.standard_struct_def(name, default)
  end

  defp struct_pattern(%BuiltIn{name: name}, module, prefix) do
    BinFormat.FieldType.Util.standard_struct_pattern(name, module, prefix)
  end 

  defp bin_pattern(%BuiltIn{name: name, type: type, size: size, options: options}, module, prefix) do
    BinFormat.FieldType.Util.standard_bin_pattern(name, type, size, 
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
