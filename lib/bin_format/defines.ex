defmodule BinFormat.Defines do
  @moduledoc """
  Build function implementation snippets from a list of fields.
  """

  alias BinFormat.Pattern, as: Pattern

  defmacro define_struct() do

    quote do

      members = BinFormat.FieldServer.get_fields(__MODULE__)

      defs = Enum.map(members, fn(member) -> 
        BinFormat.Field.struct_definition(member, __MODULE__)
      end)
        
      defs_filtered = Enum.filter_map(defs,
        fn(pattern) -> pattern != :undefined end,
        fn({:ok, pattern}) -> pattern end)

      defstruct defs_filtered
    end
  end 

  defmacro define_decode() do
    quote [unquote: false] do
      members = BinFormat.FieldServer.get_fields(__MODULE__)

      def decode(unquote(Pattern.binary_match_pattern(members, __MODULE__, "dec_"))) do
        unquote(Pattern.struct_build_pattern(members, __MODULE__, "dec_"))
      end
    end
  end

  defmacro define_encode() do
    quote unquote: false do
      members = BinFormat.FieldServer.get_fields(__MODULE__)

      def encode(var = unquote(Pattern.struct_match_pattern(members, __MODULE__, "enc_"))) do
        unquote(Pattern.binary_build_pattern(members, __MODULE__, "enc_"))
      end
    end
  end

  @doc """
  Automatically define an implementation of the `BinFormat.Format`
  function for a Module.
          
  It is used internally and will be removed from the public API soon.
  """

  def build_proto_impl(module) do
    Code.eval_quoted(quote do
      defimpl BinFormat.Format, for: unquote(module) do
        def encode(spec) do
          apply(unquote(module), :encode, [spec])
        end
      end
    end)
  end


  defmacro build_code(members, module) do
    quote do
      #unquote(define_struct(members, module))
      #unquote(define_decode(members, module))
      #unquote(define_encode(members, module))

      BinFormat.Defines.build_proto_impl(__MODULE__)
    end
  end

end
