defmodule SingleTest do
  use ExUnit.Case
  doctest Single

  test "greets the world" do
    assert Single.hello() == :world
  end
end
