defmodule DataTransformatorTest do
  use ExUnit.Case

  import A4C.DataTransformator

  test "data transformation" do
    data = [[1], [2], [3]]
    assert normalize(data) === [[0.0], [0.5], [1.0]]
    data = [[1, 0.5, 100], [2, 1.0, 200], [3, 1.5, 300]]
    assert normalize(data) === [[0.0, 0.0, 0.0], [0.5, 0.5, 0.5], [1.0, 1.0, 1.0]]
  end

  test "auxiliary list creation" do
    list = initiate_auxiliary_list(3)
    assert list === [{nil, nil}, {nil, nil}, {nil, nil}]
    list = create_auxiliary_list(list, [[1, 0.1, "a"], [2, 0.2, "b"], [3, 0.25, "ab"]])
    assert list === [{1, 3}, {0.1, 0.25}, {"a", "b"}]
  end
end