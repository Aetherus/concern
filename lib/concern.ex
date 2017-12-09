defmodule Concern do
  @moduledoc """
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
  """

  @doc """
  Register a callback which will be called when the concern is used by a normal module.
  """
  defmacro using(do: block) do
    quote do: @_using unquote(block)
  end

  @doc """
  Register a callback which will be called before compiling a normal module using the current concern.
  """
  defmacro before_compile(do: block) do
    quote do: @_before_compile unquote(block)
  end

  @doc false
  defmacro __using__(_) do
    quote do
      # In the context of newly defined concern
      @_is_concern true
      Module.register_attribute(__MODULE__, :_concerns, accumulate: true, persist: false)
      import Concern, only: [using: 1, before_compile: 1]
      Concern.def__using__()
      @before_compile {Concern, :def_helpers}
      
      defmacro __hook_before_compile__(_) do
        quote do
          hooks = @_concerns
                  |> Enum.reverse()
                  |> Enum.map(fn concern -> concern.__before_compile_hooks__ end)
          Module.eval_quoted(__MODULE__, {:__block__, [], hooks})
        end
      end
    end
  end

  @doc false
  defmacro def_helpers(_) do
    quote do
      def __using_hooks__ do
        @_concerns
        |> Enum.reverse()
        |> Enum.reduce([], fn(concern, acc) -> acc ++ concern.__using_hooks__ end)
        |> Kernel.++([@_using])
      end

      def __before_compile_hooks__ do
        @_concerns
        |> Enum.reverse()
        |> Enum.reduce([], fn(concern, acc) -> acc ++ concern.__before_compile_hooks__ end)
        |> Kernel.++([@_before_compile])
      end

      def __uses__?(concern) do
        Enum.any?(@_concerns, fn c -> c == concern or c.__uses__?(concern) end)
      end
    end
  end

  @doc false
  defmacro def__using__ do
    quote do
      # In the context of newly defined concern
      defmacro __using__(_) do
        quote do
          # In the context of user

          concern = unquote(__MODULE__)

          if Module.get_attribute(__MODULE__, :_is_concerns) do
            # user is a concern
            if !Enum.any?(@_concerns, fn c -> c == concern or c.__uses__?(concern) end) do
              @_concerns concern
            end
          else
            # user is a normal module
            if !Module.get_attribute(__MODULE__, :_concerns) do
              Module.register_attribute(__MODULE__, :_concerns, accumulate: true, persist: false)
            end

            if !Enum.any?(@_concerns, fn c -> c == concern or c.__uses__?(concern) end) do
              @_concerns concern
              hooks = concern.__using_hooks__
              Module.eval_quoted(__MODULE__, {:__block__, [], hooks})
              @before_compile {concern, :__hook_before_compile__}
            end
          end
        end
      end
    end
  end

end
