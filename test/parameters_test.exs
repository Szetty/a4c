defmodule ParametersTest do
  use ExUnit.Case

  import A4C.Parameters

  test "parameter initialization" do
    {ret, parameters} = A4C.Parameters.start({1, 2, 0.63, 0.5, 0.4, 0.25, 0.75})
    assert ret === :ok
    assert get_s_x(parameters) === 1
    assert get_s_y(parameters) === 2
    assert get_alfa(parameters) === 0.63
    assert get_lambda(parameters) === 0.5
    assert get_theta(parameters) === 0.4
    assert get_k_alfa(parameters) === 0.25
    assert get_k_lambda(parameters) === 0.75
  end

  test "parameter updates" do
  	{ret, parameters} = A4C.Parameters.start({1, 2, 0.63, 0.5, 0.4, 0.25, 0.75})
    assert ret === :ok
    update_alfa(parameters, 0.5, 0.4)
    assert get_alfa(parameters) === 0.605
    update_lambda(parameters, 0.5, 5) 
    assert get_lambda(parameters) === 9.5
  end
end