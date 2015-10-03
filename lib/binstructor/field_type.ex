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
      @packet_members [record | @packet_members]
    end
  end

  defmacro padding(value) do
    quote do
      record = {:padding, unquote(value)}
      @packet_members [record | @packet_members]
    end
  end

  defmacro ip_addr(name, default, options \\ []) do
    quote do
      record = {:ip_addr, unquote(name), unquote(default), unquote(options)}
      @packet_members [record | @packet_members]
    end
  end

  defmacro lookup(name, lookup_vals, default, type, size, options \\ []) do
    quote do
      record = {:lookup, unquote(name), unquote(lookup_vals), unquote(default), 
                 unquote(type), unquote(size), unquote(options)}
      @packet_members [record | @packet_members]
    end
  end

  defp standard_type(type, name, default, size, options) do
    quote do
      record = {:standard_type, unquote(type), unquote(name), unquote(default), 
                  unquote(size), unquote(options)}
      @packet_members [record | @packet_members]
    end
  end

  @doc """
  Build the struct definition record for a standard Elixir binary type and
  add it to the packet_members attribute
  """
  def build_record({:standard_type, type, name, default, size, options}) do
    # Build the AST for the binary pattern for both building and matching
    bin_pattern = standard_bin_pattern(name, type, size, options)

    # Build the AST for desclaring this field in a struct
    struct_def = standard_struct_def(name, default)

    # Build the AST for matching this field in a struct
    struct_pattern = standard_struct_pattern(name)

    # Build a struct with the AST needed to build each part of the operation
    record = %Binstructor.FieldType{
      struct_definition: struct_def,
      struct_build_pattern: struct_pattern,
      struct_match_pattern: struct_pattern,
      bin_build_pattern: bin_pattern,
      bin_match_pattern: bin_pattern
    }
  end


  def build_record({:padding, value}) do
    record = %Binstructor.FieldType{bin_build_pattern: Macro.escape(value), bin_match_pattern: padding_match(value)}
  end

  def build_record({:ip_addr, name, default, options}) do
    record = %Binstructor.FieldType{
      struct_definition:  standard_struct_def(name, default),
      struct_build_pattern: ip_struct_pattern(name),
      struct_match_pattern: ip_struct_pattern(name),
      bin_build_pattern: ip_bin_pattern(name, options),
      bin_match_pattern: ip_bin_pattern(name, options)
    }
  end

  def build_record({:lookup, name, lookup_vals, default, type, size, options}) do
    bin_match_pattern = standard_bin_pattern(name, type, size, options)
    bin_build_pattern = lookup_bin_pattern(name, type, size, options, lookup_vals)

    record = %Binstructor.FieldType{
      struct_definition: standard_struct_def(name, default),
      struct_build_pattern: lookup_struct_pattern(name, lookup_vals),
      struct_match_pattern: standard_struct_pattern(name),
      bin_match_pattern: bin_match_pattern,
      bin_build_pattern: bin_build_pattern
    }
  end

  def build_record({constant, value}) do
    record = %Binstructor.FieldType{bin_build_pattern: value, bin_match_pattern: value}
  end

  defp standard_bin_pattern(name, type, size, options) do
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

  defp standard_struct_def(name, default) do
    quote do
      {unquote(name), unquote(Macro.escape(default))}
    end
  end

  defp standard_struct_pattern(name) do
      struct_pattern = quote do
        {unquote(name), unquote(Macro.var(name, __MODULE__))}
      end
  end



  defp padding_match(val) when is_binary(val) do
    quote do
      _ :: binary-size(unquote(byte_size(val)))
    end
  end
 
  defp padding_match(val) when is_bitstring(val) do
    quote do
      _ :: bitstring-size(unquote(bit_size(val)))
    end
  end


  defp suffix_atom(name, suffix) do
    String.to_atom(Atom.to_string(name) <> suffix)
  end


  defp ip_struct_pattern(name) do
    a_name = suffix_atom(name, "_ip_a")
    b_name = suffix_atom(name, "_ip_b")
    c_name = suffix_atom(name, "_ip_c")
    d_name = suffix_atom(name, "_ip_d")

    quote do
      {unquote(name), 
        {unquote(Macro.var(a_name, __MODULE__)),
         unquote(Macro.var(b_name, __MODULE__)),
         unquote(Macro.var(c_name, __MODULE__)),
         unquote(Macro.var(d_name, __MODULE__))}}
    end
  end

  defp ip_bin_pattern(name, options) do
    a_name = Macro.var(suffix_atom(name, "_ip_a"), __MODULE__)
    b_name = Macro.var(suffix_atom(name, "_ip_b"), __MODULE__)
    c_name = Macro.var(suffix_atom(name, "_ip_c"), __MODULE__)
    d_name = Macro.var(suffix_atom(name, "_ip_d"), __MODULE__)

    little_endian = Enum.member?(options, :little)

    if little_endian do
      quote do
        <<unquote(d_name), unquote(c_name), unquote(b_name), unquote(a_name)>>
      end
    else
      quote do
        <<unquote(a_name), unquote(b_name), unquote(c_name), unquote(d_name)>>
      end
    end

  end




  defp lookup_bin_pattern(name, type, size, options, lookup_vals) do
    option_vars = Enum.map([type], fn(opt) -> Macro.var(opt, __MODULE__) end)

    pattern_options = option_vars ++ case size do
      :undefined -> []
      _ -> [quote do size(unquote(size)) end]
    end

    case_block = quote do
      case unquote(Macro.var(name, __MODULE__)) do
        # Flat_map is required to pull generated values up to the level expected by case
        unquote(Enum.flat_map(lookup_vals, fn({raw, val}) ->
          quote do
            unquote(Macro.escape(val)) -> unquote(Macro.escape(raw))
          end
        end))
      end
    end



    quote do
      unquote(case_block) :: unquote(Enum.reduce(pattern_options, fn(rhs, lhs) ->
        quote do
          unquote(lhs) - unquote(rhs)
        end
      end))
    end
  end

  defp lookup_struct_pattern(name, lookup_vals) do

    quote do
      {unquote(name),
        case unquote(Macro.var(name, __MODULE__)) do(
          # Flat_map is required to pull generated values up to the level expected by case
          unquote(Enum.flat_map(lookup_vals, fn({raw, val}) ->
            quote do
              unquote(Macro.escape(raw)) -> unquote(Macro.escape(val))
            end
          end)))
        end
      }
    end

  end


end


