defmodule Binstructor.Packet do

  defmacro __using__(_opts) do
    quote do
      import Binstructor.Packet
    end
  end

  defmacro defpacket(do: block) do


    members = get_members(block)

    quote do
      defstruct unquote(members)
      unquote(build_decode(block))
    end
  end

  defp eval_members({:__block__, env, mem_defs}) do
  end

  defp get_member({:=, _, [{name, _, _}, {_type, _, [default | _]}]}) do
    {name, default}
  end

  defp get_member(_line) do
    :undefined
  end

  defp get_members({:__block__, _, mem_defs}) do
    Enum.map(mem_defs, &get_member/1)
    |> Enum.reject(fn(x) -> x == :undefined end)
  end

  defp build_decode_match({:=, env, [{name, _, _}, {type, _, params}]}) do
    size = Enum.at(params, 1, :undefined)
    opts = Enum.at(params, 2, [])
    

    type_node = [{type, [], Elixir}]
    size_node = case size do
      :undefined -> []
      size -> [{:size, [], [size]}]
    end

    opt_nodes = type_node ++ Enum.map(opts, fn(val) -> {val, [], Elixir} end) ++ size_node

    opt_tree = Enum.reduce(opt_nodes, fn(x, acc) -> {:-, env, [acc, x]} end)

    {:::, env, [{name, [], Elixir}, opt_tree]}
  end
  
  defp build_set_mem({:=, _env, [nnode = {name, _, _,}, {_type, _, _}]}) do
    {name, {name, [], Elixir}}
  end

  defp build_decode({:__block__, _env, lines}) do
    quote do
      def decode(_data) do
        << unquote_splicing(Enum.map(lines, &build_decode_match/1)) >> = _data
        
        %__MODULE__{unquote_splicing(Enum.map(lines, &build_set_mem/1))}
      end
    end 
  end


end
