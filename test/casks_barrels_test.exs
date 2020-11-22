defmodule CasksBarrelsTest do
  use ExUnit.Case
  doctest CasksBarrels

  test "greets the world" do
    assert CasksBarrels.hello() == :world
  end
end
