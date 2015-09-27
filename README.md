Binstructor
=========

Binstructor makes it easy to deal with simple but large binary formats in Elixir by
generating the boilerplate code for you, including a Struct definition,
encode and decode functions.

Writing a binary pattern match for 37 different fields is tedious, so let Binstructor do it for
you from a simple declaritive description that's easy to compare to the spec!

## Usage

To define a new packet structure, create a module and add the
Binstructure.Packet module with `use Binstructor.Packet`. This will add the
`defpacket` macro which is where you define your fields.

Each field in the packet is defined by a function call. Basic data types are
identified with the same name as in a binary pattern match.

### Data Types
Binstructor supports the following data types:

#### Standard
Data types supported directly in Elixir binaries. These are passed through directly.

- integer
- binary
- float
- bits
- bitstring
- bytes
- utf8
- utf16
- utf32

#### Packet Structure

- constant
- padding

#### Convenience

- ip_addr

## Example
```
defmodule Foo do
  defstruct a: 0, b: 10, c: <<1,2,3,4>>, d:3

  def decode(<<a :: integer-size(8), b :: integer-size(8), c :: binary-size(4), d :: integer-size(8)>>) do
    %Foo{a: a, b: b, c: c, d: d}
  end

  def encode(%Foo{a: a, b: b, c: c, d: c}) do
    <<a :: integer-size(8), b :: integer-size(8), c :: binary-size(4), d::integer-size(8)>>
  end
end
```

becomes

```
defmodule Foo do
  use Binstructor.Packet

  @c_default <<1,2,3,4>>

  defpacket do
    integer :a, 0, 8
    integer :b, 10, 8
    binary :c, @c_default, 3
    integer :d, 3, 8
  end
end
```

## Metaprogramming
The body of defpacket supports metaprogramming like normal Elixir code.
The fields in the binary are defined to be in the order that the functions
declaring them are called. This can be used to automatically build packet
structures from machine readable specifications.

For Example:
```
  defpacket do
    integer :first, 0, 8

    names = [{:a1, {:a2, <<1,2,3>>}}, {:b1, {:b2, <<2,3,4>>}}, {:c1, {:c2, <<3,4,5>>}}]

    Enum.map(names, fn({v1, {v2, default}}) ->
      integer v1, 0, 8
      binary v2, default, 3
    end)

    integer :last, 0, 8
  end
```

is equivalent to

```
    defpacket do
      integer :first, 0, 8

      integer :a1, 0, 8
      binary :a2, <<1,2,3>>, 3

      integer :b1, 0, 8
      binary :b2, <<2,3,4>>, 3

      integer :c1, 0, 8
      binary :c2, <<3,4,5>>, 3

      integer :last, 0, 8
    end
  end
```

