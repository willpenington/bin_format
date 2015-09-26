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

defmodule Binstructor.Packet do

  defmacro __using__(_opts) do
    quote do
      import Binstructor.Packet
    end
  end

  defmacro defpacket(do: block) do
    

    #members = get_members(block)

    #inspect(members)


    quote do

      mod = defmodule Packet do
        import Binstructor.DataTypes        

        @packet_members []

        unquote(block)

        def packet_members() do
          @packet_members
        end

      end

      Packet.packet_members()

      #defstruct unquote(members)
      #unquote(build_decode(block))

      Binstructor.Packet.build_struct(members)
      
      Binstructor.Packet.build_decode(members)

    end

    members = build_members(block)

    quote do
      unquote(build_struct(members))
      unquote(build_decode(members))
    end

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
        %__MODULE__{
          unquote_splicing(Enum.map(members, fn({name, _}) ->
            quote do
              {unquote(name), unquote(Macro.var(name, Elixir))}
            end
          end))
        }
      end
    end
  end

  def build_binary_pattern(members) do
    quote do
      << unquote_splicing(Enum.map(members, &build_single_binary_pattern/1)) >>
    end
  end

  def build_single_binary_pattern({name, {type, _default, size, options}}) do
    quote do
      unquote(Macro.var(name, Elixir)) :: unquote(Macro.var(type,Elixir))-size(unquote(size))
    end
  end

end
