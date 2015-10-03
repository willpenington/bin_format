defmodule Binstructor.Packet do

  defmacro __using__(_opts) do
    quote do
      import Binstructor.Packet
    end
  end

  @doc """
  Defines the structure of a packet.

  Fields of the packet are defined with calls to the macros in
  Binstructor.FieldType (which is automatically imported). The field descriptor
  macros should be called in the order the fields appear in the binary packet.

  ## Examples
  A simple packet with a constant header and three integer fields would be
  described as follows:

  ```
  defmodule Foo do
    use Binstructor.Packet

    @c_default <<1,2,3,4>>

    defpacket do
      constant << "Foo" >>
      integer :a, 0, 8
      integer :b, 10, 8
      integer :c, 3, 8
    end
  end
  ```
  This is equivalent to writing the following code manually:
   ```
   defmodule Foo do
     defstruct a: 0, b: 10, c: <<1,2,3,4>>, d:3

     def decode(<<"Foo", a :: integer-size(8), b :: integer-size(8), c integer-size(8)>>) do
       %Foo{a: a, b: b, c: c}
     end

     def encode(%Foo{a: a, b: b, c: c}) do
       <<"Foo", a :: integer-size(8), b :: integer-size(8), c d::integer-size(8)>>
     end
  end
  ```



  """
  defmacro defpacket(do: block) do
    members = define_fields(block)

    body = quote do
      unquote(define_struct(members, __MODULE__))
      unquote(define_decode(members, __MODULE__))
      unquote(define_encode(members, __MODULE__))
     
      # Has to be in the quote block to make sure it gets executed
      # after the module is defined 
      Binstructor.Packet.build_proto_impl(__MODULE__)
    end

    IO.puts(Macro.to_string(body))

    body

  end

  @doc """
  Encodes any struct defined through Binstructor as a binary.

  If the struct is defined through Binstructor using the defpacket module
  then this function will automatically call the `encode\1` function from the 
  module where the packet structure is defined.

  If the struct is not defined using Binstructor the call will fail even if
  the module contains an `encode\1` function as the function may have
  undesirable side effects, however implementing the `Binstructor.PacketProto`
  protocol for a type will cause it to work with this function.
  """
  def encode(struct) do
    Binstructor.PacketProto.encodeimpl(struct)
  end

  @doc """
  Automatically define an implementation of the `Binstructor.PacketProto`
  function for a Module.
  """
  def build_proto_impl(module) do
    Code.eval_quoted(quote do
      defimpl Binstructor.PacketProto, for: unquote(module) do
        def encodeimpl(spec) do
          apply(unquote(module), :encode, [spec])
        end
      end
    end)
  end

  defp define_fields(block) do
    name = String.to_atom("Binstructor.TempPacket" <> inspect(make_ref))

    {result, _} = Code.eval_quoted(quote do

      mod = defmodule unquote(name) do
        import Binstructor.FieldType       

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

    Enum.map(result, &Binstructor.FieldType.build_record/1)
  end

  defp define_struct(members, module) do
    defs = Enum.map(members, fn(member) -> 
      Binstructor.Field.struct_definition(member, module)
    end)
      
    defs_filtered = Enum.filter_map(defs,
      fn(pattern) -> pattern != :undefined end,
      fn({:ok, pattern}) -> pattern end)

    quote do
      defstruct [unquote_splicing(defs_filtered)]
    end
  end 

  defp define_decode(members, module) do
    quote do
      def decode(unquote(binary_match_pattern(members, module, "dec_"))) do
        unquote(struct_build_pattern(members, module, "dec_"))
      end
    end
  end

  defp define_encode(members, module) do
    quote do
      def encode(var = unquote(struct_match_pattern(members, module, "enc_"))) do
        unquote(binary_build_pattern(members, module, "enc_"))
      end
    end
  end

  defp binary_build_pattern(members, module, prefix) do
    patterns = Enum.map(members, fn(member) -> 
      Binstructor.Field.bin_build_pattern(member, module, prefix)
    end)
      
    filtered_patterns = Enum.filter_map(patterns,
      fn(pattern) -> pattern != :undefined end,
      fn({:ok, pattern}) -> pattern end)

    quote do
      << unquote_splicing(filtered_patterns) >>
    end
  end

  defp binary_match_pattern(members, module, prefix) do
    patterns = Enum.map(members, fn(member) -> 
      Binstructor.Field.bin_match_pattern(member, module, prefix)
    end)
    
    filtered_patterns = []

    filtered_patterns = Enum.filter_map(patterns,
      fn(pattern) -> pattern != :undefined end,
      fn({:ok, pattern}) -> pattern end)

    quote do
      << unquote_splicing(filtered_patterns) >>
    end
  end

  defp struct_match_pattern(members, module, prefix) do
    patterns = Enum.map(members, fn(member) -> 
      Binstructor.Field.struct_match_pattern(member, module, prefix)
    end)
      
    filtered_patterns = Enum.filter_map(patterns,
      fn(pattern) -> pattern != :undefined end,
      fn({:ok, pattern}) -> pattern end)

    quote do
      %__MODULE__{
        unquote_splicing(filtered_patterns)
       }
    end
  end

  defp struct_build_pattern(members, module, prefix) do
    patterns = Enum.map(members, fn(member) -> 
      Binstructor.Field.struct_build_pattern(member, module, prefix)
    end)
      
    filtered_patterns = Enum.filter_map(patterns,
      fn(pattern) -> pattern != :undefined end,
      fn({:ok, pattern}) -> pattern end)

    quote do
      %__MODULE__{
        unquote_splicing(filtered_patterns)
       }
    end
  end

end
