defprotocol BinFormat.Field do
  @fallback_to_any true

  @moduledoc """
  Converts information about the field into snippets of Elixir AST that can be
  used to define it instructs and match against it in structs and binaries if
  necessary.

  If field generates code for a given function, it should return a tuple with
  `{:ok, ast}` where ast is the standard Elixir ast to be inserted with unquote.
  
  If the field does not require any code for a given function because it should
  be ignored (i.e. a constant that only appears in the binary matches) it
  should return the atom `:undefined`.
  """

  @doc """
  The code needed to define the field in the struct definition.

  If code should be inserted return `{:ok, ast}` where ast is the quoted Elixir
  code to insert into the definition. Struct definition elements are
  represented as a two element tupple containing the name (as an atom) and the
  default value.

  If no code should be inserted (because the field doesn't need to be in the
  struct) the atom `:undefined` is returned.
  """
  def struct_definition(field, module)

  @doc """
  The code used to insert this field into a struct.

  If this field is part of the struct for the packet this function should
  return `{:ok, ast}` where ast is the quoted Elixir code to insert when
  building a struct to represent the packet. The code should assume any
  variables needed were created by `struct_match_pattern/3` or
  `bin_match_pattern/3`. If a prefix is supplied it should be appended to the
  start of any user supplied part of the field variable name. The field names
  used in the struct should match those generated in `struct_definition/2`.

  Module is the name of the module where variables should be interpreted as
  being as an atom.

  If no code should be inserted (because the field doesn't need to be in the
  struct) the atom `:undefined` is returned.
  """
  def struct_build_pattern(field, module, prefix \\ "")

  @doc """
  The code used to match for this field against a struct.

  If this field is part of the struct for the packet this function should
  return `{:ok, ast}` where ast is the quoted Elixir code to insert when
  matching against a struct represeting the packet. The code should create
  any variables needed by `struct_build_pattern/3` or `bin_build_pattern/3`.
  If a prefix is supplied it should be appeded to the start of any user
  supplied part of the field variable name. The field names used in the struct
  should match those generated in `struct_definition/2`.
  
  Module is the name of the module where variables should be interpreted as
  being as an atom.

  If no code should be inserted (because this field doesn't need to be in the
  struct) the atom `:undefined` is returned.
  """
  def struct_match_pattern(field, module, prefix \\ "")

  @doc """
  The code used to insert this field into a binary.

  If this field appears in the binary for the packet this function should
  return `{:ok, ast}` where ast is the quoted Elixir code to insert when
  building a binary representation of the packet. The code should assume any
  variables needed were created by `struct_match_pattern/3` or
  `bin_match_pattern/3`. If a prefix is supplied it should be appended to the
  start of any user supplied part of the field variable name. 

  Module is the name of the module where variables should be interpreted as
  being as an atom.

  If no code should be inserted (becasue the field doesn't need to be in the
  binary) the atom `:undefined` is returned.
  """
  def bin_build_pattern(field, module, prefix \\ "")

  @doc """
  The code used to match for this field against a binary.

  If this field appears in the binary for the packet this function should
  return `{:ok, ast}` where ast is the quoted Elixir code to insert when
  matching against a binary representation of the packet. The code should 
  create any variables needed by `struct_build_pattern/3` or
  `bin_build_pattern/3`. If a prefix is supplied it should be appened to the
  start of any user supplied part of the field variable name. 

  Module is the name of the module where variables should be interpreted as
  being as an atom.

  If no code should be inserted (becasue the field doesn't need to be in the
  binary) the atom `:undefined` is returned.
  """
  def bin_match_pattern(field, module, prefix \\ "")

end

# Default implementation allows other code in the defformat block
defimpl BinFormat.Field, for: Any do
  def struct_definition(_, _) do
    :undefined
  end

  def struct_build_pattern(_field, _module, _prefix) do
    :undefined
  end

  def struct_match_pattern(_field, _module, _prefix) do
    :undefined
  end

  def bin_build_pattern(_field, _module, _prefix) do
    :undefined
  end 
  
  def bin_match_pattern(_field, _module, _prefix) do
    :undefined
  end
end
