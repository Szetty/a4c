defmodule AntTest do
  use ExUnit.Case

  import A4C.Ant

  test "distance calculating" do
    assert calculate_distance_square([16], [24]) === 64
    assert calculate_distance_square([24], [16]) === 64
    assert calculate_distance_square([3, 4], [6, 8]) === 25
    assert calculate_distance_square([1, 2, 3, 4, 5, 6, 0, 7, 8, 9, 10], [3, 6, 5, 7, 9, 8, 3, 10, 11, 13, 12]) === 100
    (calculate_distance_square([0.72, 4.3, 1/3], [0.91, 3.9, 1/6]) - 20149 / 90000) |> assert_epsilon
  end

  test "fitness part calculating" do
  	(calculate_fitness_part(0.63, [0.6, 0.8], [0.3, 0.4]) - 0.613541505) |> assert_epsilon
  end

  test "probability computing" do
  	(compute_probability(1/:math.pi, 1) - 0.877582561) |> assert_epsilon
  	(compute_probability(2/:math.pi, 3) - 0.157728605) |> assert_epsilon
  end

  test "fitness computing" do
    result = [] 
    |> compute_fitness(0.5, 1, 1, 1)
    assert result === 0.0
    result = [[0.5], [0.5], [0.5], [0.5], [0.5], [0.5], [0.5], [0.5], [0.5]] 
    |> compute_fitness([0.5], 1, 1, 1)
    assert result === 1.0
  end

  test "modulo calculation" do
    assert mod(2, 3) === 2
    assert mod(-5, 8) === 3
    assert mod(45, 31) === 14
    assert mod(81, 3) === 0
    assert mod(-3, 3) === 0
    assert mod(-11, 8) === 5
  end

  defp assert_epsilon(epsilon) do
  	assert ((epsilon < 0.0000001) and (epsilon >= 0)) or ((epsilon <= 0) and (epsilon > -0.0000001))
  end
end