defmodule IpAddrTest do
  use ExUnit.Case

  defmodule IpAddrPacket do
    use BinFormat

    defpacket do
      ip_addr :a, {12, 13, 14, 15}
      ip_addr :b, {21, 22, 23, 24}, [:little]
    end
  end

  @sample_binary << 31, 32, 33, 34, 44, 43, 42, 41>>

  defp sample_struct do
    %IpAddrPacket{a: {31, 32, 33, 34}, b: {41, 42, 43, 44}}
  end

  test "IP addresses encode from the format used by inet, big endian default" do
    assert IpAddrPacket.encode(sample_struct) == @sample_binary
  end

  test "IP addresses decode from the format used by inet, big endian default" do
    assert IpAddrPacket.decode(@sample_binary) == sample_struct
  end
end
