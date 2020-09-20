defmodule WhithatTest do
  use ExUnit.Case
  doctest Whithat
  doctest Whithat.Bvid
  doctest Whithat.Video.BiliBili

  test "greets the world" do
    assert Whithat.hello() == :world
  end

  test "Bvid Encode" do
    assert Whithat.Bvid.encode(67719840) == "BV1PJ411A727"
    assert Whithat.Bvid.encode(795519616) == "BV1kC4y1W71T"
  end

end
