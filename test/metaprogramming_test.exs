defmodule MetaprogrammingTest do
  use ExUnit.Case

  defmodule MetaPacket do
    use Binstructor.Packet

    defpacket do
      integer :first, 0, 8

      names = [{:a1, {:a2, <<1,2,3>>}}, {:b1, {:b2, <<2,3,4>>}}, {:c1, {:c2, <<3,4,5>>}}]

      Enum.map(names, fn({v1, {v2, default}}) ->
        integer v1, 0, 8
        binary v2, default, size
      end)

      integer :last, 0, 8
    end
  end

  sample_packet = <<1, 2, 11,12,13, 3, 22,23,24, 4, 33,34,35, 5>>

  test "member definitions are treated like function calls in metaprogramming" do
    s = %MetaPacket{}

    assert Map,has_key?(s, :a1)
    assert Map.has_key?(s, :a2)
    assert Map.has_key?(s, :b1)
    assert Map.has_key?(s, :b2)
    assert Map.has_key?(s, :c1)
    assert Map.has_key?(s, :c2)

  end

  test "normal definitions are not affected by metaprogramming" do
    s = %MetaPacket{}

    assert Map.has_key?(s, :first)
    assert Map.has_key?(s, :last)
  end

  test "memebers decode in the order that the functions are called" do
    s = MetaPacket.decode(sample_packet)
 
    assert s.first = 1,
    
    assert s.a1 = 2
    assert s.a2 = <<11,12,13>>
 
    assert s.b1 = 3
    assert s.b2 = <<22, 23, 24>>

    assert s.c1 = 4
    assert s.c2 = <<33, 34, 35>>

    assert s.last = 5
  end


end
