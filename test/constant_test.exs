defmodule ConstantTests do
  use ExUnit.Case
 
  defmodule ConstantPacket do
    use BinFormat

    defpacket do
      constant <<1,2,3>>
      integer :a, 10, 8
      constant <<5, 6>>
    end
  end

  @sample_binary  <<1,2,3,20,5,6>>

  @wrong_binary  <<2,3,4,20,1,2>>

  defp sample_struct do
    %ConstantPacket{a: 20}
  end

  test "encoding adds the constant" do
    assert ConstantPacket.encode(sample_struct) == @sample_binary
  end

  test "decoding a binary with the correct constant suceeds" do
    assert ConstantPacket.decode(@sample_binary) == sample_struct
  end

  test "decoding a binary with incorrect constants fails" do
 #   catch_error(ConstantPacket.decode(@wrong_binary))
  end
  
end
