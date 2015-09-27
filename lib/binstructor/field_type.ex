defmodule Binstructor.FieldType do
  defstruct struct_definition: nil, struct_pattern: nil, bin_encode_pattern: nil, bin_decode_pattern: nil


  defp standard_type(type, name, default, size, options) do
    quote do

      bin_pattern = standard_bin_pattern(unquote(name), unquote(type), unquote(size), unquote(options))



      record = %Binstructor.FieldType{
        struct_definition: standard_struct_def(unquote(name), unquote(default)),
        struct_pattern: standard_struct_pattern(unquote(name)),
        bin_encode_pattern: bin_pattern,
        bin_decode_pattern: bin_pattern
      }

      @packet_members [record | @packet_members]
    end
  end

  def standard_bin_pattern(name, type, size, options) do
    option_vars = Enum.map([type], fn(opt) -> Macro.var(opt, __MODULE__) end)

    pattern_options = option_vars ++ case size do
      :undefined -> []
      _ -> [quote do size(unquote(size)) end]
    end

    quote do
      unquote(Macro.var(Macro.expand(name, __ENV__), __MODULE__)) :: unquote(Enum.reduce(pattern_options, fn(rhs, lhs) ->
        quote do
          unquote(lhs) - unquote(rhs)
        end
      end))
    end
  end

  def standard_struct_def(name, default) do
    quote do
      {unquote(name), unquote(Macro.escape(default))}
    end
  end

  def standard_struct_pattern(name) do
      struct_pattern = quote do
        {unquote(name), unquote(Macro.var(name, __MODULE__))}
      end
  end

  defmacro integer(name, default, size, options \\ []) do
    IO.inspect({:integer, name})
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

  defmacro constant(value) do

    record = %Binstructor.FieldType{bin_encode_pattern: value, bin_decode_pattern: value}

    quote do
      @packet_members [unquote(Macro.escape(record)) | @packet_members]
    end
  end


  def padding_decode(val) when is_binary(val) do
    quote do
      _ :: binary-size(unquote(byte_size(val)))
    end
  end
 
  def padding_decode(val) when is_bitstring(val) do
    quote do
      _ :: bitstring-size(unquote(bit_size(val)))
    end
  end

  defmacro padding(value) do
    quote do

    record = %Binstructor.FieldType{bin_encode_pattern: unquote(Macro.escape(value)), bin_decode_pattern: padding_decode(unquote(value))}

    @packet_members [record | @packet_members]
    end
  end

end


