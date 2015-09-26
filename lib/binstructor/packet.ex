defmodule Binstructor.DataTypes do

  defmacro integer(name, default, size, options \\ []) do
    quote do
     @packet_members [{unquote(name), {:integer, unquote(default), unquote(size), unquote(options)}} | @packet_members]
    end
  end

  defmacro binary(name, default, size, options \\ []) do
    quote do
     @packet_members [{unquote(name), {:binary, unquote(default), unquote(size), unquote(options)}} | @packet_members]
    end
  end
end

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

    quote do
      unquote(build_struct(members))
      unquote(build_decode(members))
      unquote(build_encode(members))
     
      # Has to be in the quote block to make sure it gets executed
      # after the module is defined 
      Binstructor.Packet.build_proto_impl(__MODULE__)
    end

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
        import Binstructor.DataTypes        

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
        Enum.map(members, fn({name, {_type, default, _size, _opts}}) ->
          {name, Macro.escape(default)}
        end)
      )]
    end
  end 

  def build_decode(members) do
    quote do
      def decode(unquote(build_binary_pattern(members))) do
        unquote(build_struct_pattern(members))
      end
    end
  end

  def build_encode(members) do
    quote do
      def encode(var = unquote(build_struct_pattern(members))) do
        unquote(build_binary_pattern(members))
      end
    end
  end

  def build_binary_pattern(members) do
    quote do
      << unquote_splicing(Enum.map(members, &build_single_binary_pattern/1)) >>
    end
  end

  def build_struct_pattern(members) do
    quote do
      %__MODULE__{
        unquote_splicing(Enum.map(members, fn({name, _}) ->
          quote do
            {unquote(name), unquote(Macro.var(name, __MODULE__))}
          end
        end))
      }
    end
  end

  def build_single_binary_pattern({name, {type, _default, size, _options}}) do
    quote do
      unquote(Macro.var(name, __MODULE__)) :: unquote(Macro.var(type,__MODULE__))-size(unquote(size))
    end
  end

end
