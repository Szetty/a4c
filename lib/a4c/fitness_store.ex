defmodule A4C.FitnessStore do

	use ExActor.GenServer
	@doc """
		state -> fitness_map::HashDict(ley=pid of ant, value=fitness)
	"""
	
	defstart start() do
		initial_state(HashDict.new)
	end

	defcast add_fitness(ant, fitness), state: fitness_map do
		fitness_map = HashDict.put(fitness_map, ant, fitness)
		new_state(fitness_map)
	end

	defcall get_fitness_map(), state: fitness_map do
		reply(fitness_map)
	end
	
end