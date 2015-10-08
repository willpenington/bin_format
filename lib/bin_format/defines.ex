defmodule BinFormat.Defines do
  @moduledoc """
  Build function implementation snippets from a list of fields.
  """

  alias BinFormat.Pattern, as: Pattern

  def define_struct(members, module) do
    defs = Enum.map(members, fn(member) -> 
      BinFormat.Field.struct_definition(member, module)
    end)
      
    defs_filtered = Enum.filter_map(defs,
      fn(pattern) -> pattern != :undefined end,
      fn({:ok, pattern}) -> pattern end)

    quote do
      defstruct [unquote_splicing(defs_filtered)]
    end
  end 

  def define_decode(members, module) do
    quote do
      def decode(unquote(Pattern.binary_match_pattern(members, module, "dec_"))) do
        unquote(Pattern.struct_build_pattern(members, module, "dec_"))
      end
    end
  end

  def define_encode(members, module) do
    quote do
      def encode(var = unquote(Pattern.struct_match_pattern(members, module, "enc_"))) do
        unquote(Pattern.binary_build_pattern(members, module, "enc_"))
      end
    end
  end

end
