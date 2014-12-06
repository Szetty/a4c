defmodule A4C.Ant do
	use ExActor.GenServer

	@doc """
		state -> {pid, data::list}
	"""

	defstart start(data) do
		initial_state({nil, data})
	end 

	defcall set_pid(pid), state: {_, data} do
		set_and_reply({pid, data}, :ok)
	end

	defcast work(grid, s_x, s_y, alfa, lambda, theta, fitness_map, data_store, class_store), state: {pid, data} do
		{{x_ant, y_ant}, upper_bound} = A4C.Grid.get_grid_and_bound(grid, pid)
		neighbours = get_neighbour_ants(s_x, s_y, x_ant, y_ant, grid, upper_bound, data_store)
		fitness = neighbours
			|> Enum.reduce([], fn {_, data}, list -> list ++ [data] end)
			|> compute_fitness(data, s_x, s_y, alfa)
		A4C.FitnessStore.add_fitness(fitness_map, pid, fitness)
		position = nil
		limit = (2*s_x+1)*(2*s_y+1) - 1
		nr = Enum.count(neighbours)
		if(nr !== limit && nr > 0) do
			probability = compute_probability(fitness, lambda)
			rand = :random.uniform
			if(rand <= probability) do
				empty_positions = get_empty_positions(s_x, s_y, x_ant, y_ant, grid, upper_bound)
				if(Enum.count(empty_positions) > 0) do
					position = get_new_position(theta, empty_positions, s_x, s_y, grid, alfa, data, upper_bound, data_store)
				end
			end
			neighbours = neighbours |> Enum.reduce([], fn {ant, _}, list -> list ++ [ant] end)
			{class, _} = get_class_frequency([pid | neighbours], class_store) 
				|> Enum.reduce(fn {class, frequency}, {best_class, best_frequency} -> 
					if(best_frequency >= frequency) do
						{best_class, best_frequency}
					else
						{class, frequency}
					end 
				end)
			A4C.ClassStore.update_class(class_store, pid, class)
		end
		if(position != nil) do
			A4C.Grid.update_ant_position(grid, pid, position) 
		end
		noreply
	end

	def get_neighbour_ants(s_x, s_y, x_ant, y_ant, grid, upper_bound, data) do
		get_neighbour_ants(x_ant - s_x, y_ant - s_y, x_ant + s_x, y_ant - s_y, y_ant + s_y, upper_bound, x_ant, y_ant, grid, data)
	end

	def get_neighbour_ants(i, _, i_end, _, _, _, _, _, _, _) when i > i_end, do: []

	def get_neighbour_ants(i, j, i_end, j_start, j_end, upper_bound, x_ant, y_ant, grid, data) when j > j_end do
		get_neighbour_ants(i+1, j_start, i_end, j_start, j_end, upper_bound, x_ant, y_ant, grid, data)
	end

	def get_neighbour_ants(i, j, i_end, j_start, j_end, upper_bound, x_ant, y_ant, grid, data) do
		x = mod(i, upper_bound)
		y = mod(j, upper_bound)
		if((x !== x_ant) or (y !== y_ant)) do
			ant = A4C.Grid.get_ant(grid, {x, y})
			if((ant !== nil)) do
				[{ant, A4C.DataStore.get_data(data, ant)} | get_neighbour_ants(i, j+1, i_end, j_start, j_end, upper_bound, x_ant, y_ant, grid, data)]
			else
				get_neighbour_ants(i, j+1, i_end, j_start, j_end, upper_bound, x_ant, y_ant, grid, data)
			end
		else
			get_neighbour_ants(i, j+1, i_end, j_start, j_end, upper_bound, x_ant, y_ant, grid, data)
		end
	end

	def get_new_position(theta, empty_positions, s_x, s_y, grid, alfa, data, upper_bound, data_store) do
		rand = :random.uniform()
		if(rand <= theta) do
			get_best_position(empty_positions, grid, s_x, s_y, alfa, data_store, data, upper_bound)
		else
			rand = :random.uniform(Enum.count(empty_positions)) - 1
			Enum.at(empty_positions, rand)
		end
	end

	def get_best_position(empty_positions, grid, s_x, s_y, alfa, all_data, data, upper_bound) do
		get_best_position(empty_positions, grid, s_x, s_y, alfa, all_data, data, upper_bound, {-1, nil})
	end

	def get_best_position([], _, _, _, _, _, _, _, {_, position}), do: position

	def get_best_position([{x, y} | empty_positions], grid, s_x, s_y, alfa, data_store, data, upper_bound, {fitness, position}) do
		neighbours = get_neighbour_ants(s_x, s_y, x, y, grid, upper_bound, data_store)
		new_fitness = neighbours
		|> Enum.reduce([], fn {_, data}, list -> list ++ [data] end)
		|> compute_fitness(data, s_x, s_y, alfa)
		if(fitness >= new_fitness) do
			get_best_position(empty_positions, grid, s_x, s_y, alfa, data_store, data, upper_bound, {fitness, position})
		else
			get_best_position(empty_positions, grid, s_x, s_y, alfa, data_store, data, upper_bound, {new_fitness, {x, y}})
		end
	end

	#Definition 3: empty position
	def get_empty_positions(s_x, s_y, x_ant, y_ant, grid, upper_bound) do
		get_empty_positions(x_ant - s_x, y_ant - s_y, x_ant + s_x, y_ant - s_y, y_ant + s_y, x_ant, y_ant, grid, upper_bound)
	end

	def get_empty_positions(i, _, i_end, _, _, _, _, _, _) when i > i_end, do: []

	def get_empty_positions(i, j, i_end, j_start, j_end, x_ant, y_ant, grid, upper_bound) when j > j_end do
		get_empty_positions(i+1, j_start, i_end, j_start, j_end, x_ant, y_ant, grid, upper_bound)
	end

	def get_empty_positions(i, j, i_end, j_start, j_end, x_ant, y_ant, grid, upper_bound) do
		i_new = mod(i, upper_bound)
		j_new = mod(j, upper_bound)
		if(((i_new !== x_ant) or (j_new !== y_ant)) and (!A4C.Grid.has_position?(grid, {i_new, j_new}))) do
			[{i_new, j_new}] ++ get_empty_positions(i, j+1, i_end, j_start, j_end, x_ant, y_ant, grid, upper_bound)
		else
			get_empty_positions(i, j+1, i_end, j_start, j_end, x_ant, y_ant, grid, upper_bound)
		end
	end

	#Definition 4: distance
	def calculate_distance_square([], []) do
		0
	end

	def calculate_distance_square([number1 | data1], [number2 | data2]) do
		calculate_distance_square(data1, data2) + (number1 - number2) * (number1 - number2)
	end

	#Definition 5: fitness
	def compute_fitness(neighbour_datas, data, s_x, s_y, alfa) do
		denominator = (2*s_x + 1)*(2*s_y + 1)
		nominator = neighbour_datas
		|> Enum.reduce(0, fn current, accumulator -> accumulator + calculate_fitness_part(alfa, data, current) end)
		(nominator / denominator)
	end

	def calculate_fitness_part(alfa, data, current) do
		distance_square = data |> calculate_distance_square(current)
		:math.pow(alfa, 2) / (:math.pow(alfa, 2) + distance_square)
	end

	#Defintion 6: probability
	def compute_probability(fitness, lambda) do
		(fitness * :math.pi / 2) |> :math.cos |> :math.pow(lambda)
	end

	#Calculate modulo, positive modulo for negative integers too
	def mod(a,b) do
		rem(rem(a,b) + b, b)
	end

	def get_class_frequency(neighbours, class_store) do
		get_class_frequency(neighbours, class_store, HashDict.new) |> HashDict.to_list
	end

	def get_class_frequency([], _, frequncies) do
		frequncies
	end

	def get_class_frequency([neighbour | neighbours], class_store, dict) do
		class = A4C.ClassStore.get_class(class_store, neighbour)
		if(HashDict.has_key?(dict, class)) do
			new_dict = HashDict.put(dict, class, dict[class] + 1)
			get_class_frequency(neighbours, class_store, new_dict)
		else
			get_class_frequency(neighbours, class_store, HashDict.put(dict, class, 1))
		end
	end
end