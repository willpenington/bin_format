defmodule LookupTest do
  use ExUnit.Case

  defmodule LookupPacket do
    use Binstructor.Packet

    defpacket do
      defp constants do
        [{1, :foo},
         {2, :bar},
         {3, :baz},
         {4, :bing},
         {5, :boom}]
      end


      lookup :a, [{1, :foo}, {2, :bar}, {3, :baz}, {4, :bing}, {5, :boom}], :foo, :integer, 8
      lookup  :b, [{1, :foo}, {2, :bar}, {3, :baz}, {4, :bing}, {5, :boom}], :bing, :integer, 16
    end

  end

  defp sample_struct do
    %LookupPacket{a: :baz, b: :bing}
  end

  defp sample_binary do
    <<3, 4 :: size(16)>>
  end

  test "encoding a binary converts lookup values to raw values" do
    assert LookupPacket.encode(sample_struct) == sample_binary
  end

  test "decoding a binary will lookup values to use in struct" do
    assert LookupPacket.decode(sample_binary) == sample_struct
  end

  test "encoding with a value not defined in the lookup fails" do
    catch_error(LookupPacket.encode(%LookupPacket{a: :oops, b: :ouch}))
  end

  test "decoding values without a defined lookup fails" do
    catch_error(LookupPacket.decode(<<11, 12 :: size(16) >>))
  end

end
