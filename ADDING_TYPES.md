# Adding Custom Field Types
In this example we will build a simplified version of the IP address type to
use in the defformat macro. Any data type can be added to BinFormat by adding
a new implementation of the `BinFormat.Field` type and a macro to add it to the
list of fields in `defformat`.

Like the standard ip_addr implementation, we will use the IP address format
used by the Erlang :inet modules in the struct and a 32 bit integer in the
binary. This example will ignore any options such as little endian support for
simplicity but you can refer to the standard implementation to see how it can
be handled.

## Defining the Module
The first step is to define the module that will hold our implentation. This
can be part of your existing application and can have any name, but it makes it
easier if the last section of the module name is a camel case version of the
macro you want to use in defformat. We will call the module for this example
`MyIPAddr` and the macro `my_ip_addr`.

To start with our module needs to contain a struct. Two fields are needed to
build the IP address type: a name and a default. The name is used for
generating variables and the default is used for struct definition. We give
the nil as the default for both fields because we expect the values to be fully
populated by our own code every time a struct is created.

We write our module initial module code as follows:
```
defmodule MyIPAddr do
  defstruct name: nil, default: nil
end
```

## Implementing the Field protocol
The defformat macro builds the patterns and functions by retrieving the AST
snippets it needs through the `BinFormat.Field` protocol. For our new module
to be useful we must define an implementation. Normally this can be done after
the module definition in the same file as the module is quite short. After
adding the protocol implementation the file should look like this:
```
defmodule MyIPAddr do
  defstruct name: nil, default: nil
end

defimpl BinFormat.Field, for: MyIPAddr do
end
```

There are five main functions in this protocol:
* `struct_definition`
* `struct_match_pattern`
* `struct_build_pattern`
* `bin_match_pattern`
* `bin_build_pattern`

### struct_definition
The struct definition is easy to implement because it is the same for almost
every type. Either the field does not appear in the struct (for example a 
constant) and the function returns `:undefined` or it is declared with the
supplied name and default.

`BinFormat.FieldType.Util.standard_struct_def` will return the correct code for
normal field types. Under the hood it escapes the value of the default and
returns `name: default` in a tupple tagged with `:ok` to indicated the field
exists.

The module argument is provided in case any variables or functions need to be
accessed in their correct enviroment. They normally don't in the struct
definition so we will mark it with an underscore but in the rest of the
functions it will be used as an argument to `Macro.var`. See the Elixir
documentation on Macros for more information.

The code for `struct_definition` looks like this and goes in the defimpl's do
block:
```
def struct_definition(%MyIPAddr{name: name, default: default}, _module) do
  BinFormat.FieldType.Util.standard_struct_def(name, default)
end
```
### struct_match_pattern
The `struct_match_pattern` returns the code needed to extract the data
from a struct with pattern matching and store it in a variable. Like with the
`struct_definition` function, there is a standard function in the 
`BinFormat.FieldType.Util` module but in this case we need to write our own.
The standard function takes the name of the field and extracts the member of
the struct with that name and stores it in a variable with (a prefixed version
of) the same name.

The variable we are trying to match is a tuple with four terms and the name in
the struct is exactly the same as the name supplied, so we need to match
something like this:
```
address: {a, b, c, d}
```

Internally, matches for structs are just a prop list, so that becomes a tuple
with the name as an atom on the left and our ip on the right:
```
{:address, {a, b, c, d}}
```

The four variables we are creating need to be picked up by the code that builds
the binary later so we need to give them unique but predictable names
incoperating the field name and supplied prefix (in this case "pfix\_"):
```
{:address, {ip_a_pfix_address, ip_b_pfix_address, ip_c_pfix_address, 
              ip_d_pfix_address}
```

The prefix argument should be inserted just before the user
supplied part of any variable name used in the code snippet returned to allow
BinFormat to avoid naming conflicts in generated code.

We now have the code we want to insert, so we need to quote it to return the
AST. We have the base name as an atom, the prefix as a string and we know the
custom prefixes we want to give each variable so we can split the values out.
We will define a helper function called `var_name` and add it to the defimpl
block with defp to keep it private. The Elixir Macro library provides the `var`
function to turn an atom into a variable reference so we will build up an atom
for the full name first then return a variable name that can be inserted
directly into the code. The module argument is required for giving the variable
the correct scope.

```
defp var_name(name, part, prefix, module) do
  full_name = String.to_atom(prefix <> arg <> Atom.to_string(name))
  Macro.var(full_name, module)
end
```

We can now build up our code block by inserting the names with unquote.
This is all we need to build the implementation of `struct_match_pattern`.
The result is returned inside a tuple tagged with `:ok` to indicate that code
needs to be inserted.

```
def struct_match_pattern(%MyIpAddr{name: name}, module, prefix) do
  a_name = var_name(name, "ip_a_", prefix, module)
  b_name = var_name(name, "ip_b_", prefix, module)
  c_name = var_name(name, "ip_c_", prefix, module)
  d_name = var_name(name, "ip_d_", prefix, module)

  pattern = quote do
    {unquote(name), {unquote(a_name), unquote(b_name), unquote(c_name), 
                      unquote(d_name)}
  end

  {:ok, pattern}
end
```

### struct_build_pattern
The struct build pattern is like `struct_match_pattern`, but it is used when
building structs from existing local variables defined by code in
`bin_match_pattern` or `struct_match_pattern`. Normally the code snippet
returned by this function will be inserted after `bin_match_pattern` but all
returned code should use the same set of variables to make the field type
future proof.

In this case the code snippet needed is the same as the one returned by
`struct_match_pattern` as we will set up `bin_match_pattern` to initialise
the same variables.

We don't want to rewrite the code so we will copy the contents of the
`struct_match_pattern` to a private helper function and call it from both
`struct_match_pattern` and `struct_build_pattern`:

```
defp struct_pattern(%MyIpAddr{name: name}, module, prefix) do
  a_name = var_name(name, "ip_a_", prefix, module)
  b_name = var_name(name, "ip_b_", prefix, module)
  c_name = var_name(name, "ip_c_", prefix, module)
  d_name = var_name(name, "ip_d_", prefix, module)

  pattern = quote do
    {unquote(name), {unquote(a_name), unquote(b_name), unquote(c_name), 
                      unquote(d_name)}
  end

  {:ok, pattern}
end

def struct_match_pattern(field, module, prefix) do
  struct_pattern(field, module, prefix)
end

def struct_build_pattern(field, module, prefix) do
  struct_pattern(field, module, pattern)
end
```

It is not always possible to use the same pattern for building and matching,
particularly if any logic needs to be applied building the value. For example,
the built in lookup field type uses the standard functions from
`BinFormat.FieldType.Util` for matching but custom functions that generate
a pattern incoperating the case statement for building the values.

We could have used the standard versions of the match functions and then used 
function calls to extract the relevant data from the tuple or binary in the 
build functions but it is better to use pattern matching where possible.

### bin_match_pattern
The `bin_match_pattern` function is the equivalent of `struct_match_pattern`
for matching against binaries. We will use the same approach.

The pattern we want to match (with a name of address and prefix of "pfix\_"):
```
<<... ip_a_pfix_address, ip_b_pfix_address, ip_c_pfix_address, ip_d_pfix_address, ...>>
```

As binary subexpressions are valid as terms in binary matches, this is
equivalent to the following:
```
<<... <<ip_a_pfix_address, ip_b_pfix_address, ip_c_pfix_address, ip_d_pfix_address>>, ...>>
```
This is easier to generate so it is what we will use.

We can use the same `var_name` function as before, so the fuctions becomes:
```
def bin_match_pattern(%MyIPAddr{name: name}, module, prefix) do
  a_name = var_name(name, "ip_a_", prefix, module)
  b_name = var_name(name, "ip_b_", prefix, module)
  c_name = var_name(name, "ip_c_", prefix, module)
  d_name = var_name(name, "ip_d_", prefix, module)

  pattern = quote do
    <<unquote(a_name), unquote(b_name), unquote(c_name), unquote(d_name)>>
  end

  {:ok, pattern}
end
```

As before we generate the snippet with a quote expression and return it tagged
with the atom `:ok`


### bin_build_pattern
This function generates the representation of the binary when the variables
are already declared in a match pattern. Like `struct_build_pattern`, we can
reuse the `bin_match_pattern` function for `bin_build_pattern` by putting the
logic in a private function.
```
defp bin_pattern(%MyIPAddr{name: name}, module, prefix) do
  a_name = var_name(name, "ip_a_", prefix, module)
  b_name = var_name(name, "ip_b_", prefix, module)
  c_name = var_name(name, "ip_c_", prefix, module)
  d_name = var_name(name, "ip_d_", prefix, module)

  pattern = quote do
    <<unquote(a_name), unquote(b_name), unquote(c_name), unquote(d_name)>>
  end

  {:ok, pattern}
end

def bin_match_pattern(field, module, prefix) do
  bin_pattern(field, module, prefix)
end

def bin_build_pattern(field, module, prefix) do
  bin_pattern(field, module, prefix)
end
```

## defformat Body Macro
We now have a working implementation of the BinFormat.Field protocol, but to
use it we need to be able to add instances to the field list. To do this we
need to define a macro we can call in the body of defformat.

The macro generates a quoted snippet of code that builds an instance of the
struct from its arguments and passes it to the
`BinFormat.FieldType.Util.add_field\\1` function that generates the correct
code to insert into the defformat block. A quote block containing the struct
literal with each field set to the relevant unquoted argument will generate
the correct snippet. The quote block can be pipelined directly into the
`add_field` function. Passing the macro without quoting it will not work.

```
defmacro my_ip_addr(name, default) do
  quote do
    %MyIPAddr{name: unquote(name), default: unquote(default)}
  end
  |> BinFormat.FieldType.Util.add_field()
end
```

The arguments to the macro should match the fields in the struct. Sometimes a
module may have more than one macro, for example the built in types share an
implementation but `integer :a, 2, 8` is easier to understand than 
`builtin :integer, :a, 2, 8`. If it makes sense to put this kind of logic in
your macros you should.

The macro can be defined anywhere but it should normally go in the same module
as the struct. 

## Using the New Type
The definition of our new type is now complete and we are ready to use it in
defformat. The macro will not be picked up automatically but it can be refered
to by its full name.

```
defmodule MyFormat do
  use BinFormat
  
  defformat do
    MyIPAddr.my_ip_addr :address, {127, 0, 0, 1}
  end
```

You can import the module where it is defined to access it more easily if
needed. 

```
defmodule MyFormat do
  use BinFormat

  defformat do
    import MyIPAddr

    my_ip_addr :address1, {127, 0, 0, 1}
    my_ip_addr :address2, {192, 168, 1, 1}
  end
end
```

For more advanced uses the defformat macro can be wrapped by a macro that
imports the needed modules at the start of the do block.

## Conclusion
We have now built and used a simplified version of the standard ip_addr type.
You can take a look at the source code of the standard version on GitHub for to
see how the little endian option is implemented and the other types for ideas
on how to implement what you need.

If you have any problems following this guide or getting your types to work,
please raise an issue on this project's
[GitHub Repository](https://github.com/willpenington/bin_format).
