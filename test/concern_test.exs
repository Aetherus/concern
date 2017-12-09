defmodule ConcernTest do
  use ExUnit.Case
  doctest Concern

  defmodule X do
    use A
    use C_AB
    use B_A
  end

  test "using/1 block expands in the context of normal module" do
    assert X.b == "b"
    assert X.c == "c"
  end

  test "before_compile/1 block expands in the context of normal module" do
    assert X.aa == "aa"
    assert X.cc == "cc"
  end

  test "using/1 and before_compile/1 blocks of each concern are invoked only once" do
    assert X.x == "x in C"
    assert X.xx == "xx in C"
  end

  test "__MODULE__ in the using/1 and before_compile/1 refers to the normal module" do
    assert X.a_mod == X
    assert X.b_mod == X
    assert X.c_mod == X
  end

end
