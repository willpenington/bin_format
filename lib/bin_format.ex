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

  The 

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
    quote do
      BinFormat.FieldServer.start_link(__MODULE__)

      import BinFormat.FieldType.Constant
      import BinFormat.FieldType.Padding
      import BinFormat.FieldType.Boolean
      import BinFormat.FieldType.IpAddr
      import BinFormat.FieldType.Lookup
      import BinFormat.FieldType.BuiltIn


      unquote(block)

      require BinFormat.Defines
      BinFormat.Defines.build_code

      BinFormat.FieldServer.stop(__MODULE__)

    end
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

end
