defmodule BinFormat.Pattern do
  @moduledoc """
  Build Elixir pattern snippets from a list of fields
  """

  def binary_build_pattern(members, module, prefix) do
    patterns = Enum.map(members, fn(member) -> 
      BinFormat.Field.bin_build_pattern(member, module, prefix)
    end)
      
    filtered_patterns = Enum.filter_map(patterns,
      fn(pattern) -> pattern != :undefined end,
      fn({:ok, pattern}) -> pattern end)

    quote do
      << unquote_splicing(filtered_patterns) >>
    end
  end

  def binary_match_pattern(members, module, prefix) do
    patterns = Enum.map(members, fn(member) -> 
      BinFormat.Field.bin_match_pattern(member, module, prefix)
    end)
    
    filtered_patterns = []

    filtered_patterns = Enum.filter_map(patterns,
      fn(pattern) -> pattern != :undefined end,
      fn({:ok, pattern}) -> pattern end)

    quote do
      << unquote_splicing(filtered_patterns) >>
    end
  end

  def struct_match_pattern(members, module, prefix) do
    patterns = Enum.map(members, fn(member) -> 
      BinFormat.Field.struct_match_pattern(member, module, prefix)
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

  def struct_build_pattern(members, module, prefix) do
    patterns = Enum.map(members, fn(member) -> 
      BinFormat.Field.struct_build_pattern(member, module, prefix)
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
