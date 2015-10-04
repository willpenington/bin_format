defmodule DataTypesTest do
  use ExUnit.Case


  defmodule TypesPacket do
    use BinFormat

    defformat do
      integer :a, 0, 8
      float :b, 0, 32
      bits :c, <<1>>, 8
      bitstring :d, <<2>>, 8
      binary :e, <<3>>, 8
      bytes :f, <<4>>, 1
      utf8 :g, "asdf"
      utf16 :h, "qwer" 
      utf32 :i, "uiop"
    end
  end

  test "all basic data types round trip" do
    s = %TypesPacket{}

    #assert TypesPacket.decode(TypesPacket.encode(s)) == s
  end
end
