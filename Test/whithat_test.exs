defmodule WhithatTest do
  use ExUnit.Case
  doctest Whithat
  doctest Whithat.Video.BiliBili

  test "greets the world" do
    assert Whithat.hello() == :world
  end

end
