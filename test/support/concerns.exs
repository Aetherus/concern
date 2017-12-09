defmodule A do
  use Concern

  before_compile do
    quote do
      def aa, do: "aa"
      def xx, do: "xx in A"
      def a_mod, do: __MODULE__
      defoverridable [xx: 0]
    end
  end
end

defmodule B_A do
  use Concern
  use A

  using do
    quote do
      def b, do: "b"
      def x, do: "x in B"
      def b_mod, do: a_mod
      defoverridable [x: 0]
    end
  end

end

defmodule C_AB do
  use Concern
  use A
  use B_A

  using do
    quote do
      def c, do: "c"
      def x, do: "x in C"
      def c_mod, do: b_mod
      defoverridable [x: 0]
    end
  end

  before_compile do
    quote do
      def cc, do: "cc"
      def xx, do: "xx in C"
      defoverridable [xx: 0]
    end
  end
end
