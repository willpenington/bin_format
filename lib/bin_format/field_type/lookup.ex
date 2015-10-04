defmodule BinFormat.FieldType.Lookup do
  defstruct name: nil, lookup_vals: nil, default: nil, type: nil, size: nil, options: nil

  defmacro lookup(name, lookup_vals, default, type, size, options \\ []) do
    field = quote do
      %BinFormat.FieldType.Lookup{name: unquote(name), 
        lookup_vals: unquote(lookup_vals), default: unquote(default), 
        type: unquote(type), size: unquote(size), options: unquote(options)}
    end
    BinFormat.FieldType.Util.add_field(field)
  end

end

defimpl BinFormat.Field, for: BinFormat.FieldType.Lookup do
  alias BinFormat.FieldType.Lookup, as: Lookup

  def struct_definition(%Lookup{name: name, default: default}, _module) do
    BinFormat.FieldType.Util.standard_struct_def(name, default)
  end

  def struct_build_pattern(%Lookup{name: name, lookup_vals: lookup_vals}, module, prefix) do
    full_name = String.to_atom(prefix <> Atom.to_string(name))
    var_name = Macro.var(full_name, module)

    pattern = quote do
      {unquote(name),
        case unquote(var_name) do(
          # Flat_map is required to pull generated values up to the level expected by case
          unquote(Enum.flat_map(lookup_vals, fn({raw, val}) ->
            quote do
              unquote(Macro.escape(raw)) -> unquote(Macro.escape(val))
            end
          end)))
        end
      }
    end
    
    {:ok, pattern}
  end

  def struct_match_pattern(%Lookup{name: name}, module, prefix) do
    BinFormat.FieldType.Util.standard_struct_pattern(name, module, prefix)
  end

  def bin_build_pattern(%Lookup{name: name, type: type, size: size, options: options, lookup_vals: lookup_vals}, module, prefix) do

    option_vars = Enum.map([type | options], fn(opt) -> Macro.var(opt, __MODULE__) end)

    pattern_options = option_vars ++ case size do
      :undefined -> []
      _ -> [quote do size(unquote(size)) end]
    end

    full_name = String.to_atom(prefix <> Atom.to_string(name))
    var_name = Macro.var(full_name, module)

    case_block = quote do
      case unquote(var_name) do
        # Flat_map is required to pull generated values up to the level expected by case
        unquote(Enum.flat_map(lookup_vals, fn({raw, val}) ->
          quote do
            unquote(Macro.escape(val)) -> unquote(Macro.escape(raw))
          end
        end))
      end
    end

    pattern = quote do
      unquote(case_block) :: unquote(Enum.reduce(pattern_options, fn(rhs, lhs) ->
        quote do
          unquote(lhs) - unquote(rhs)
        end
      end))
    end

    {:ok, pattern}
  end

  def bin_match_pattern(%Lookup{name: name, type: type, size: size, options: options}, module, prefix) do
    BinFormat.FieldType.Util.standard_bin_pattern(name, type, size, options, module, prefix)
  end
end
