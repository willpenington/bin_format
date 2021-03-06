defmodule BinFormat.FieldType.IpAddr do
  defstruct name: nil, default: nil, options: []

  @moduledoc """
  :inet style IP address field type for defformat. 
  """

  @doc """
  Add an IP address field to the format structure in defformat.

  This field type decodes IP addresses represented as 32 bit integers in
  binaries directly into the tuple format used by the networking modules in the
  Erlang standard library. For example, it will transform the binary value 
  `<< 192, 168, 1, 1 >>` into `{192, 168, 1, 1}` and vice versa.

  By default the binary value will be treated as big endian. To use a little
  endian encoding add the atom `:little` to the list of options.
  """
  defmacro ip_addr(name, default, options \\ []) do
    field = quote do
      %BinFormat.FieldType.IpAddr{name: unquote(name), 
        default: unquote(default), options: unquote(options)}
    end

    quote do
      BinFormat.FieldType.Util.add_field(unquote(field), __ENV__)
    end
  end

end

defimpl BinFormat.Field, for: BinFormat.FieldType.IpAddr do
  alias BinFormat.FieldType.IpAddr, as: IpAddr

  defp struct_pattern(%IpAddr{name: name}, module, prefix) do
    a_name = full_name(name, "_ip_a", prefix)
    b_name = full_name(name, "_ip_b", prefix)
    c_name = full_name(name, "_ip_c", prefix)
    d_name = full_name(name, "_ip_d", prefix)

    pattern = quote do
      {unquote(name),
        {unquote(Macro.var(a_name, module)),
         unquote(Macro.var(b_name, module)),
         unquote(Macro.var(c_name, module)),
         unquote(Macro.var(d_name, module))}}
    end

    {:ok, pattern}
  end

  defp bin_pattern(%IpAddr{name: name, options: options}, module, prefix) do
    a_name = Macro.var(full_name(name, "_ip_a", prefix), module)
    b_name = Macro.var(full_name(name, "_ip_b", prefix), module)
    c_name = Macro.var(full_name(name, "_ip_c", prefix), module)
    d_name = Macro.var(full_name(name, "_ip_d", prefix), module)

    little_endian = Enum.member?(options, :little)

    pattern = if little_endian do
      quote do
        <<unquote(d_name), unquote(c_name), unquote(b_name), unquote(a_name)>>
      end
    else
      quote do
        <<unquote(a_name), unquote(b_name), unquote(c_name), unquote(d_name)>>
      end
    end

    {:ok, pattern}
  end

  defp full_name(name, arg, prefix) do
    String.to_atom(prefix <> arg <> Atom.to_string(name))
  end
  def struct_definition(%IpAddr{name: name, default: default}, _module) do
    BinFormat.FieldType.Util.standard_struct_def(name, default)
  end

  def struct_match_pattern(fields, module, prefix) do
    struct_pattern(fields, module, prefix)
  end

  def struct_build_pattern(fields, module, prefix) do
    struct_pattern(fields, module, prefix)
  end

  def bin_match_pattern(fields, module, prefix) do
    bin_pattern(fields, module, prefix)
  end

  def bin_build_pattern(fields, module, prefix) do
    bin_pattern(fields, module, prefix)
  end
end
