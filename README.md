bin_format
=========

bin_format generates the Elixir code for handling binary formats throuh
structs. The code created by bin_format is the same as you would write by hand,
but the fields and their order are kept in one place.

The format description is done through the defformat macro, which uses a set of
macros designed to make long specifications easy to transcribe and supports
metaprogramming.

## Getting Started
You can add bin_format to your project as a dependency from hex. Just add
`{:bin_format, "~> 0.0.1"}` to your mix file's deps section.

The documentation can be found 
[here](http://hexdocs.pm/bin_format/0.0.1/extra-api-reference.html).

## Supported Field Types
The full documentation for supported field types can be found in the ExDoc
files for the `BinFormat.FieldType.*` modules.

### Built In
Types supported in standard Elixir byte strings

* `integer`
* `binary` (and `bytes`)
* `bitstring` (and `bits`)
* `float`
* `utf8`
* `utf16`
* `utf32`

### Formatting
* `constant` - Must be present for binary patterns to match
* `padding` - Ignored on binary decode, set to a default on binary encode

### Convenience
* `ip_addr` - IP addresses in the :inet {a,b,c,d} format
* `lookup` - Replace a decoded value with an Elixir term from a list
* `boolean` - Maps 0 to false and everything else to true

### Custom
Additional field types can be added by creating implentations
of the `BinFormat.Field` protocol and wrapping the 
`BinFormat.FieldType.Util.add_field` macro. See ADDING_TYPES.md for more
details.

## Usage

To define a new format, create a module and add the BinFormat module with 
`use BinFormat`. This will add the `defformat` macro which is where you define
the fields and their order.

Each field in the packet is defined by a macro call.

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
  use BinFormat

  defformat do
    integer :a, 0, 8
    integer :b, 10, 8
    binary :c, <<1,2,3,4>>, 3
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
defformat do
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
defformat do
  integer :first, 0, 8

  integer :a1, 0, 8
  binary :a2, <<1,2,3>>, 3

  integer :b1, 0, 8
  binary :b2, <<2,3,4>>, 3

  integer :c1, 0, 8
  binary :c2, <<3,4,5>>, 3

  integer :last, 0, 8
end
```

