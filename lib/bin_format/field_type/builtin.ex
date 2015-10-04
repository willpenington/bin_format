defmodule BinFormat.FieldType.BuiltIn do
  defstruct type: nil, name: nil, default: nil, size: nil, options: []

  @moduledoc """
  Standard Elixir binary match types for defformat.

  This module implements all the types supported natively by Elixir in binary
  patterns and provides macros for adding them to a format's structure in the
  defformat macro.

  The arguments provided are directly translated into both the binary and
  struct patterns used in the generated functions. All of the macros in this
  module follow a common pattern. The binary match snippet
  ```
  << ... name :: type-option1-option2-size(16), ... >>
  ```
  becomes
  ```
  type :name, default, 16, [option1, option2]
  ```
  inside defpacket (where default is the default value used in defstruct).
  
  Size is supported on all types excepty `utf8`, `utf16` and `utf32`. Passing
  :undefined will cause the size to be ignored if options are needed but size
  would be left blank when building the code by hand. A default is mandatory
  for all types.
  """

  # Generate quote block to add a standard type field to a format structure
  defp standard_type(type, name, default, size, options) do
    field = quote do
      %BinFormat.FieldType.BuiltIn{type: unquote(type), name: unquote(name),
        default: unquote(default), size: unquote(size), 
        options: unquote(options)}
    end

    BinFormat.FieldType.Util.add_field(field)
  end
  
  @doc """
  Add an Integer field to the format structure in defformat.
  """
  defmacro integer(name, default, size \\ :undefined, options \\ []) do
    standard_type(:integer, name, default, size, options)
  end

  @doc """
  Add a Binary field to the format structure in defformat.
  """
  defmacro binary(name, default, size \\ :undefined, options \\ []) do
    standard_type(:binary, name, default, size, options)
  end 

  @doc """
  Add a Float field to the format structure in defformat.
  """
  defmacro float(name, default, size \\ :undefined, options \\ []) do
    standard_type(:float, name, default, size, options)
  end 

  @doc """
  Add a Bits field to the format structure in defformat.
  """
  defmacro bits(name, default, size \\ :undefined, options \\ []) do
    standard_type(:bits, name, default, size, options)
  end 

  @doc """
  Add a Bitstring field to the format structure in defformat.
  """
  defmacro bitstring(name, default, size \\ :undefined, options \\ []) do
    standard_type(:bitstring, name, default, size, options)
  end 

  @doc """
  Add a Bytes field to the format structure in defformat.
  """
  defmacro bytes(name, default, size \\ :undefined, options \\ []) do
    standard_type(:bytes, name, default, size, options)
  end 

  @doc """
  Add a UTF8 field to the format structure in defformat.
  """
  defmacro utf8(name, default, options \\ []) do
    standard_type(:utf8, name, default, :undefined, options)
  end 

  @doc """
  Add a UTF16 field to the format structure in defformat.
  """
  defmacro utf16(name, default, options \\ []) do
    standard_type(:utf16, name, default, :undefined, options)
  end 

  @doc """
  Add a UTF32 field to the format structure in defformat.
  """
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
