defmodule GridTest do
  use ExUnit.Case

  import A4C.Grid

  test "test upper bound computing" do
    assert compute_upper_bound(100) === 20
    assert compute_upper_bound(255) === 30
  end
end