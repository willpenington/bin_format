Binstructor
=========

Binstructor makes it easy to deal with simple but large binary formats by
generating the boilerplate Elixir code for you, including a Struct definition,
encode and decode functions and helpers for pattern matching. Writing a binary
pattern match for 37 different fields is tedious, so let Binstructor do it for
you from a simple declaritive description that's easy to compare to the spec!

# Usage

To define a new packet structure, create a module and add the
Binstructure.Packet module with `use Binstructor.Packet`. This will add the
`defpacket` macro which is where you define your fields.

Each field in the packet is defined by 

** TODO: Add examples **
