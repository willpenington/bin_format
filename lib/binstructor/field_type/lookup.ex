defmodule Binstructor.FieldType.Lookup do
  defstruct name: nil, lookup_vals: nil, default: nil, type: nil, size: nil, options: nil

  def struct_definition(%__MODULE__{name: name, default: default}, _module) do
    Binstructor.FieldType.Util.standard_struct_def(name, default)
  end

  def struct_build_pattern(%__MODULE__{name: name, lookup_vals: lookup_vals}, module, prefix) do
    full_name = String.to_atom(prefix <> Atom.to_string(name))
    var_name = Macro.var(full_name, module)

    IO.inspect("building lookup struct build pattern")

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

  def struct_match_pattern(%__MODULE__{name: name}, module, prefix) do
    Binstructor.FieldType.Util.standard_struct_pattern(name, module, prefix)
  end

  def bin_build_pattern(%__MODULE__{name: name, type: type, size: size, options: options, lookup_vals: lookup_vals}, module, prefix) do

    option_vars = Enum.map([type], fn(opt) -> Macro.var(opt, __MODULE__) end)

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

  def bin_match_pattern(%__MODULE__{name: name, type: type, size: size, options: options}, module, prefix) do
    Binstructor.FieldType.Util.standard_bin_pattern(name, type, size, options, module, prefix)
  end
end

defimpl Binstructor.Field, for: Binstructor.FieldType.Lookup do
  def struct_definition(field, module) do
    Binstructor.FieldType.Lookup.struct_definition(field, module)
  end

  def struct_build_pattern(field, module, prefix) do
    Binstructor.FieldType.Lookup.struct_build_pattern(field, module, prefix)
  end

  def struct_match_pattern(field, module, prefix) do
    Binstructor.FieldType.Lookup.struct_match_pattern(field, module, prefix)
  end

  def bin_build_pattern(field, module, prefix) do
    Binstructor.FieldType.Lookup.bin_build_pattern(field, module, prefix)
  end

  def bin_match_pattern(field, module, prefix) do
    Binstructor.FieldType.Lookup.bin_match_pattern(field, module, prefix)
  end
end
