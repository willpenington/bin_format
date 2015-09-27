
defprotocol Binstructor.PacketProto do
  def encodeimpl(struct)
end

defmodule Binstructor.Packet do

  defmacro __using__(_opts) do
    quote do
      import Binstructor.Packet
    end
  end

  defmacro defpacket(do: block) do
    members = build_members(block)

    body = quote do
      unquote(build_struct(members))
      unquote(build_decode(members))
      unquote(build_encode(members))
     
      # Has to be in the quote block to make sure it gets executed
      # after the module is defined 
      Binstructor.Packet.build_proto_impl(__MODULE__)
    end

    IO.puts(Macro.to_string(body))

    body

  end

  def encode(struct) do
    Binstructor.PacketProto.encodeimpl(struct)
  end

  def build_proto_impl(module) do
    Code.eval_quoted(quote do
      defimpl Binstructor.PacketProto, for: unquote(module) do
        def encodeimpl(spec) do
          apply(unquote(module), :encode, [spec])
        end
      end
    end)
  end

  def build_members(block) do
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

    result
  end

  def build_struct(members) do
    quote do
      defstruct [unquote_splicing(
        Enum.filter_map(members,
          fn (member) -> member.struct_definition != nil end,
          fn (member) -> member.struct_definition end)
      )]
    end
  end 

  def build_decode(members) do
    quote do
      def decode(unquote(build_binary_decode_pattern(members))) do
        unquote(build_struct_pattern(members))
      end
    end
  end

  def build_encode(members) do
    quote do
      def encode(var = unquote(build_struct_pattern(members))) do
        unquote(build_binary_encode_pattern(members))
      end
    end
  end

  def build_binary_encode_pattern(members) do
    quote do
      << unquote_splicing(Enum.filter_map(members, 
          fn(member) -> member.bin_encode_pattern != nil end,
          fn(member) -> member.bin_encode_pattern end)) >>
    end
  end

  def build_binary_decode_pattern(members) do
    quote do
      << unquote_splicing(Enum.filter_map(members, 
          fn(member) -> member.bin_decode_pattern != nil end,
          fn(member) -> member.bin_decode_pattern end)) >>
    end
  end

  def build_struct_pattern(members) do

    quote do
      %__MODULE__{
        unquote_splicing(Enum.filter_map(members,
          fn(member) -> member.struct_pattern != nil end,
          fn(member) -> member.struct_pattern end))
       }
    end
  end

end
