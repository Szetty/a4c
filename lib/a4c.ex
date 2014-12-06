defmodule A4C do

	import A4C.Parameters
	require Logger

	def start() do
		start(:iris, 5000)
	end

	def start(input, t_max) do
		initialize()
		if(t_max < 1) do
			Logger.warn "Number of iterations given is less than 1!"
		else
			input |> A4C.DataTransformator.read_data_from_csv |> A4C.DataTransformator.normalize |> run(t_max)
		end
	end

	defp initialize() do
		:random.seed(:erlang.now)
		clear_error_log()
		configure_info_logger()
	end

	defp configure_info_logger do
		{{year,month,day},{hour,min,sec}} = :erlang.localtime()
		Logger.add_backend {LoggerFileBackend, :info}
		Logger.configure_backend {LoggerFileBackend, :info},
		  path: "./log/#{year}-#{month}-#{day}_#{hour}-#{min}-#{sec}_info.log",
		  level: :info
	end

	defp clear_error_log do
		File.write!("./log/error.log", "", [:write])
	end

	defp run(data, t_max) do
		{:ok, parameters} = A4C.Parameters.start({1, 1, 0.4483, 2, 0.9, 0.5, 1})
		{:ok, fitness_store} = A4C.FitnessStore.start
		{ants, datamap, classes} = create_ants_and_stores(data, [], HashDict.new, HashDict.new, 0)
		{:ok, data_store} = A4C.DataStore.start(datamap)
		{:ok, class_store} = A4C.ClassStore.start(classes)
		{:ok, grid} = A4C.Grid.start(ants)
		ants |> Enum.each(fn ant -> A4C.Ant.set_pid(ant, ant) end)
		loop(t_max, parameters, ants, grid, fitness_store, data_store, class_store)
			|> HashDict.to_list
			|> Enum.sort(fn {ant1, _}, {ant2, _} ->
				data1 = HashDict.get(datamap, ant1)
				data2 = HashDict.get(datamap, ant2)
				index1 = Enum.find_index(data, fn (element) -> element === data1 end)
				index2 = Enum.find_index(data, fn (element) -> element === data2 end)
				index1 <= index2
			end)
			|> Enum.reduce([], fn {ant, {x, y}}, list -> list ++ [{x, y, A4C.ClassStore.get_class(class_store, ant)}] end)
			|> A4C.DataTransformator.write_result_to_csv(t_max) 	
	end

	defp create_ants_and_stores([], ants, datamap, classes, _) do
		{ants, datamap, classes}
	end

	defp create_ants_and_stores([gene | data], ants, datamap, classes, number) do
		{:ok, ant} = A4C.Ant.start(gene)
		ants = ants ++ [ant]
		Logger.info "Ant with pid #{inspect(ant)} has the data #{inspect(gene)}"
		datamap = HashDict.put(datamap, ant, gene)
		classes = HashDict.put(classes, ant, number)
		create_ants_and_stores(data, ants, datamap, classes, number+1)
	end

	defp loop(t_max, parameters, ants, grid, fitness_store, data, classes) do
		loop(1, t_max, parameters, ants, grid, fitness_store, data, classes, 0)
	end

	defp loop(t, t_max, _, _, grid, _, _, _, _) when t > t_max do
		A4C.Grid.get_grid(grid)
	end

	defp loop(1, t_max, parameters, ants, grid, fitness_store, data, classes, _) do
		alfa = get_alfa(parameters)
		lambda = get_lambda(parameters)
		theta = get_theta(parameters)
		s_x = get_s_x(parameters)
		s_y = get_s_y(parameters)
		ants |> Enum.each(fn ant -> A4C.Ant.work(ant, grid, s_x, s_y, alfa, lambda, theta, fitness_store, data, classes)	end)
		:timer.sleep(1000)
		logarithm = :math.log10(t_max)
		avg_fitness = fitness_store |> A4C.FitnessStore.get_fitness_map |> compute_average_fitness
		parameters |> A4C.Parameters.update_alfa(avg_fitness, 0)
		parameters |> A4C.Parameters.update_lambda(avg_fitness, logarithm)
		loop(2, t_max, parameters, ants, grid, fitness_store, data, classes, avg_fitness)
	end

	defp loop(t, t_max, parameters, ants, grid, fitness_store, data, classes, prev_avg_fit) do
		alfa = get_alfa(parameters)
		lambda = get_lambda(parameters)
		theta = get_theta(parameters)
		s_x = get_s_x(parameters)
		s_y = get_s_y(parameters)
		ants |> Enum.each(fn ant -> A4C.Ant.work(ant, grid, s_x, s_y, alfa, lambda, theta, fitness_store, data, classes)	end)
		logarithm = :math.log10(t_max / t)
		avg_fitness = fitness_store |> A4C.FitnessStore.get_fitness_map |> compute_average_fitness
		parameters |> A4C.Parameters.update_alfa(avg_fitness, prev_avg_fit)
		parameters |> A4C.Parameters.update_lambda(avg_fitness, logarithm)
		loop(t+1, t_max, parameters, ants, grid, fitness_store, data, classes, avg_fitness)
	end

	defp compute_average_fitness(fitness_map) do
		fitnesses = fitness_map |> HashDict.values
		n = Enum.count(fitnesses) - 1
		fitnesses
		|> Enum.reduce(0, fn fitness, avg ->
			if(fitness != nil) do
				avg + fitness / n
			else
				avg
			end 
		end)
	end
end
