defmodule PaddingTest do
  use ExUnit.Case


  defmodule PaddingPacket do
    use Binstructor.Packet

    defpacket do
      integer :a, 11, 8
      padding <<1,2>>
      padding <<3,4 :: integer-size(6) >>
      integer :b, 12, 8
    end
  end

  defp sample_struct do
    %PaddingPacket{a: 21, b: 22}
  end

  defp padding_val do
    <<1,2,3,4 :: integer-size(6)>>
  end

  defp generated_binary do
    <<21, padding_val, 22>>
  end

  @generated_binary <<21, 1, 2, 3, 4 :: size(6), 22>>
  @sample_binary <<21, 31, 32, 33, 34 :: size(6), 22>>

  test "the padding field generates the constant value supplied" do
    assert PaddingPacket.encode(sample_struct) == @generated_binary
  end

  test "the padding field accepts any value of the correct size" do
    assert PaddingPacket.decode(@generated_binary) == sample_struct
    assert PaddingPacket.decode(@sample_binary) == sample_struct
  end
end
