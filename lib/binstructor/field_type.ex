defmodule Binstructor.FieldType do
  defstruct struct_definition: nil, struct_build_pattern: nil, struct_match_pattern: nil, bin_build_pattern: nil, bin_match_pattern: nil

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
    quote do
      record = {:constant, unquote(value)}
      record = %Binstructor.FieldType.Constant{value: unquote(value)}
      @packet_members [record | @packet_members]
    end
  end

  defmacro padding(value) do
    quote do
      record = {:padding, unquote(value)}
      record = %Binstructor.FieldType.Padding{value: unquote(value)}
      @packet_members [record | @packet_members]
    end
  end

  defmacro ip_addr(name, default, options \\ []) do
    quote do
      record = {:ip_addr, unquote(name), unquote(default), unquote(options)}
      record = %Binstructor.FieldType.IpAddr{name: unquote(name), default: unquote(default), options: unquote(options)}

      @packet_members [record | @packet_members]
    end
  end

  defmacro lookup(name, lookup_vals, default, type, size, options \\ []) do
    quote do
      record = {:lookup, unquote(name), unquote(lookup_vals), unquote(default), 
                 unquote(type), unquote(size), unquote(options)}
      record = %Binstructor.FieldType.Lookup{name: unquote(name), lookup_vals: unquote(lookup_vals), default: unquote(default), type: unquote(type), size: unquote(size), options: unquote(options)}

      @packet_members [record | @packet_members]
    end
  end

  defp standard_type(type, name, default, size, options) do
    quote do
      record = {:standard_type, unquote(type), unquote(name), unquote(default), 
                  unquote(size), unquote(options)}
      record = %Binstructor.FieldType.BuiltIn{type: unquote(type), name: unquote(name), default: unquote(default), size: unquote(size), options: unquote(options)}

      @packet_members [record | @packet_members]
    end
  end

  def build_record(field) do
    field
  end
end


