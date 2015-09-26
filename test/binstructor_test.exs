defmodule BinstructorTest do
  use ExUnit.Case

  @sample_binary <<34, 23, 15, 16, 17, 18>>

  defmodule TestPacket do
    use Binstructor.Packet
    
    defpacket do
      integer :a, 0, 8
      integer :b, 15, 8
      binary :c, <<1,2,3,4>>, 4
    end
  end

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "defpacket sets up a struct" do
    s = %TestPacket{}

    assert s.__struct__ == TestPacket

    assert Map.has_key?(s, :a)
    assert Map.has_key?(s, :b)
  end

  test "decoding a binary builds a struct" do
    s = TestPacket.decode(@sample_binary)

    assert s.a == 34
    assert s.b == 23
    assert s.c == <<15, 16, 17, 18>>
  end

  test "encoding a struct builds a binary" do
    s = %TestPacket{a: 34, b: 23, c: <<15,16,17, 18>>}

    bin  = TestPacket.encode(s)

    assert bin == @sample_binary
  end
  
end
