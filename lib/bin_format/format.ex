defprotocol BinFormat.Format do
  @moduledoc """
  Common functions for all structs generated with defformat.

  All modules where BinFormat is used to generate a struct automatically have
  an implementation of the BinFormat.Format protocol. This allows any struct to
  be encoded without knowing the module where it is designed.
  """

  @doc """
  Encode any struct defined through defformat as a binary.
  """
  def encode(struct)
end
