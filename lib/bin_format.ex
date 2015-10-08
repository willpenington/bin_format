defmodule BinFormat do
  alias BinFormat.Defines, as: Defines

  defmacro __using__(_opts) do
    quote do
      import BinFormat
    end
  end

  @doc """
  Defines the structure of the format.

  The format is defined by calling field type macros in the order that the
  fields appear in the packet. The standard field types are defined in the
  `BinFormat.FieldType.*` modules, which are imported automatically. These
  macros generate a field list for the protocol which is used to build the
  patterns in the encode and decode functions. The defformat call is replaced
  by the boilerplate struct definition and encode and decode functions at
  compile time and is equivalent to writing the code manually.

  Any macro that returns `BinFormat.FieldType.Util.add_field` called with a
  valid implementation of the `BinFormat.Field` protocol can be used as a
  field type.

  Metaprogrammming within the defformat block is supported but all macro calls
  must happen in the conext of the block. See [README](extra-readme.html) for
  details.

  ## Examples
  A simple format with a constant header and three integer fields can be
  implemented as follows:

  ```
  defmodule Foo do
    use BinFormat

    defformat do
      constant << "Foo" >>
      integer :a, 0, 8
      integer :b, 10, 8
      integer :c, 3, 8
    end
  end
  ```

  This is expands to the following code when the module is compiled:

   ```
   defmodule Foo do
     defstruct a: 0, b: 10, c: 3

     def decode(<<"Foo", a :: integer-size(8), b :: integer-size(8), c integer-size(8)>>) do
       %Foo{a: a, b: b, c: c}
     end

     def encode(%Foo{a: a, b: b, c: c}) do
       <<"Foo", a :: integer-size(8), b :: integer-size(8), c d::integer-size(8)>>
     end
  end
  ```
  """
  defmacro defformat(do: block) do
    members = define_fields(block)

    body = quote do
      unquote(Defines.define_struct(members, __MODULE__))
      unquote(Defines.define_decode(members, __MODULE__))
      unquote(Defines.define_encode(members, __MODULE__))
     
      # Has to be in the quote block to make sure it gets executed
      # after the module is defined 
      BinFormat.build_proto_impl(__MODULE__)
    end

    body

  end

  @doc """
  Encodes any struct defined through BinFormat as a binary.

  If the struct is defined through BinFormat using the defpacket module
  then this function is equivalent to calling encode(struct) on the module
  directly.

  This is a convenience function implemented through the BinFormat.Format
  protocol.
  """
  def encode(struct) do
    BinFormat.Format.encode(struct)
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

  defp define_fields(block) do
    name = String.to_atom("BinFormat.TempPacket" <> inspect(make_ref))

    {result, _} = Code.eval_quoted(quote do

      mod = defmodule unquote(name) do
        import BinFormat.FieldType.BuiltIn
        import BinFormat.FieldType.Constant
        import BinFormat.FieldType.IpAddr
        import BinFormat.FieldType.Lookup
        import BinFormat.FieldType.Padding

        @packet_members []

        unquote(block)

        def packet_members() do
          @packet_members
        end

        inspect(@packet_members)
      end

      members = Enum.reverse(unquote(name).packet_members())
      
      :code.delete(unquote(name))
      :code.purge(unquote(name))


      members
    end)

    result
  end

end
