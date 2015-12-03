defmodule BinFormat.FieldType.Boolean do
  defstruct name: nil, default: nil, size: nil, options: nil

  @moduledoc """
  Boolean field type for defformat.
  """

  @doc """
  Add a Boolean field to the format structure in defformat.



  A lookup field uses a list of values and labels to map a stanard value type
  in the binary to an arbitrary Elixir value in the struct. The type is the
  name of any macro in the BinFormat.FieldType.BuiltIn module as an atom and
  the rest of the arguments are the same as they would be in that module.

  If the value read from the binary does not have a label defined in
  lookup_vals or a term in the struct does not have a matching raw value the
  encode or decode function will fail.
  """
  defmacro boolean(name, default, size, options \\ []) do
    field = quote do
      %BinFormat.FieldType.Boolean{name: unquote(name), 
        default: unquote(default), size: unquote(size), 
        options: unquote(options)}
    end
    BinFormat.FieldType.Util.add_field(field)
  end

end

defimpl BinFormat.Field, for: BinFormat.FieldType.Boolean do
  alias BinFormat.FieldType.Boolean

  def struct_definition(%Boolean{name: name, default: default}, _module) do
    BinFormat.FieldType.Util.standard_struct_def(name, default)
  end

  def struct_build_pattern(%Boolean{name: name}, module, prefix) do
    full_name = String.to_atom(prefix <> Atom.to_string(name))
    var_name = Macro.var(full_name, module)

    pattern = quote do
      {unquote(name),
        case unquote(var_name) do
          0 -> false
          x when is_integer(x) -> true
        end
      }
    end
    
    {:ok, pattern}
  end

  def struct_match_pattern(%Boolean{name: name}, module, prefix) do
    BinFormat.FieldType.Util.standard_struct_pattern(name, module, prefix)
  end

  def bin_build_pattern(%Boolean{name: name, size: size, options: options}, module, prefix) do

    option_vars = Enum.map([:integer | options], fn(opt) -> Macro.var(opt, __MODULE__) end)

    pattern_options = option_vars ++ case size do
      :undefined -> []
      _ -> [quote do size(unquote(size)) end]
    end

    full_name = String.to_atom(prefix <> Atom.to_string(name))
    var_name = Macro.var(full_name, module)

    case_block = quote do
      case unquote(var_name) do
        false -> 0
        true -> 1
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

  def bin_match_pattern(%Boolean{name: name, size: size, options: options}, module, prefix) do
    BinFormat.FieldType.Util.standard_bin_pattern(name, :integer, size, options, module, prefix)
  end
end
