defmodule BooleanTest do
  use ExUnit.Case


  defmodule BooleanPacket do
    use BinFormat

    defformat do
      boolean :a, true, 1
      padding <<0 :: size(7) >>
      boolean :b, false, 8
    end
  end

  defp sample_struct do
    %BooleanPacket{a: false, b: true}
  end

  @generated_binary <<0, 1 >>
  @sample_binary << 45, 3 >>

  test "the boolean field encodes to the atom value supplied" do
    assert BooleanPacket.encode(sample_struct) == @generated_binary
  end

  test "the boolean field decodes 1 as true and 0 as false" do
    assert BooleanPacket.decode(@generated_binary) == sample_struct
    assert BooleanPacket.decode(@sample_binary) == sample_struct
  end
end
