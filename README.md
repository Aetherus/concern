# Concern

Bring `ActiveSupport::Concern` to Elixir world.

## Example

```elixir
defmodule MyConcern do
  use Concern   

  using do
    quote do
      def who_am_i, do: __MODULE__
    end
  end

  before_compile do
    quote do
      IO.inspect(__MODULE__)
    end
  end
end

defmodule MyModule do
  use MyConcern
end

MyModule.who_am_i  #=> MyModule
```

## The problem concern tries to solve
  
The problem with mixin style modules is that, suppose you have the following modules 

```elixir
defmodule MixinA do
  defmacro __using__(_) do
    quote do
      def foo, do: __MODULE__
    end
  end
end

defmodule MixinB do
  use MixinA  

  defmacro __using__(_) do
    quote do
      def bar, do: foo
    end
  end
end

defmodule MyModule do
  use MixinB
end

MyModule.bar
```

You expect the return value be `MyModule`, but instead it gives you a `CompileError`.
That's because `foo` is injected into `MixinB`, not `MyModule`.

Maybe you'll try to call `MixinB.foo` in `bar`:

```elixir
defmodule MixinA do
  defmacro __using__(_) do
    quote do
      def foo, do: __MODULE__
    end
  end
end

defmodule MixinB do
  use MixinA  

  defmacro __using__(_) do
    quote do
      def bar, do: MixinB.foo  #<----- Note this line
    end
  end
end

defmodule MyModule do
  use MixinB
end

MyModule.bar  #=> MixinB
```

This is not you want.

Or you may try this:

```elixir
defmodule MixinA do
  defmacro __using__(_) do
    quote do
      def foo, do: __MODULE__
    end
  end
end

defmodule MixinB do
  defmacro __using__(_) do
    quote do
      def bar, do: foo
    end
  end
end

defmodule MyModule do
  use MixinA
  use MixinB
end

MyModule.bar  #=> MyModule
```

But why should `MyModule` know the existence of `MixinA` when `MyModule` directly uses nothing in `MixinA`?

With `Concern`, you can do this

```elixir
defmodule MixinA do
  use Concern

  using do
    quote do
      def foo, do: __MODULE__
    end
  end
end

defmodule MixinB do
  use Concern
  use MixinA  

  using do
    quote do
      def bar, do: foo
    end
  end
end

defmodule MyModule do
  use MixinB
end

MyModule.bar  #=> MyModule
```

## Caveat

* `using` is not parameterized.
* Can't access env in `before_compile` block.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `concern` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:concern, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/concern](https://hexdocs.pm/concern).

