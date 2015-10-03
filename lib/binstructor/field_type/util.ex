defmodule Binstructor.FieldType.Util do
  @moduledoc """
  Implementations of the AST generator functions for builtin types with the
  Binstructor.FieldType.BuiltIn struct replaced by the relevant variables.

  These functions are useful for other types and are provided to reduce
  duplication.
  """

  @doc """
  Builds a struct definition for a simple field.

  Returns the equivalent of `defstruct ... name: default, ...` in a struct definition.
  """
  def standard_struct_def(name, default) do
    struct_def = quote do
      {unquote(name), unquote(Macro.escape(default))}
    end

    {:ok, struct_def}
  end


  @doc """
  Builds a struct pattern for a simple field.

  Returns the equivalent of `%Module{... name: full_name, ...}` where full_name is 
  name with prefix appended at the start.

  This can be used for both building and matching patterns.
  """
  def standard_struct_pattern(name, module, prefix) do
    full_name = String.to_atom(prefix <> Atom.to_string(name))
    var_name = Macro.var(full_name, module)

    struct_pattern = quote do
      {unquote(name), unquote(var_name)}
    end

    {:ok, struct_pattern}
  end

  @doc """
  Builds a binary pattern for an Elixir built in binary type.

  Returns the equivalent of << ... full_name :: type-option1-option2-size(s), ... >>
  where option1 and option2 are members of the list options and s is the value
  of size.

  This can be used for both building and matching patterns.
  """
  def standard_bin_pattern(name, type, size, options, module, prefix) do
    # Turn the option atoms into variables, with type as the first option
    option_vars = Enum.map([type | options], fn(opt) -> Macro.var(opt, module) end)

    # Add size as a function call to the end of the option list
    pattern_options = option_vars ++ case size do
      :undefined -> []
      _ -> [quote do size(unquote(size)) end]
    end

    # Add the prefix to the name and convert it to a varialbe
    full_name = String.to_atom(prefix <> Atom.to_string(name))
    var_name = Macro.var(full_name, module)

    # Seperate each option with a dash
    merged_options = Enum.reduce(pattern_options, fn(rhs, lhs) ->
      quote do
        unquote(lhs) - unquote(rhs)
      end
    end)

    # Add options to name
    bin_pattern = quote do
      unquote(var_name) :: unquote(merged_options)
    end

    {:ok, bin_pattern}
  end
end
