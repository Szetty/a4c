defmodule A4C.Grid do
	use ExActor.GenServer
	require Logger

	@doc """
		state -> {agent_grid::HashDict(key=pid of ant, value=position), position_grid::HashDict(key=position, value=pid of ant), upper_bound}
	"""

	defstart start(agents) do
		upper_bound = agents |> Enum.count |> compute_upper_bound
		{agent_grid, position_grid} = HashDict.new 
		|> put_agents_on_grid(HashDict.new, agents, upper_bound)
		initial_state({agent_grid, position_grid, upper_bound})
	end

	defcall get_grid, state: {agent_grid, _, _} do
		reply(agent_grid)
	end

	defcall get_grid_and_bound(ant), state: {agent_grid, _, upper_bound} do
		{x_ant, y_ant} = HashDict.get(agent_grid, ant)
		reply({{x_ant, y_ant}, upper_bound})
	end

	defcall get_ant(position), state: {_, position_grid, _} do
		reply(position_grid[position])
	end

	defcall has_position?(position), state: {_, position_grid, _} do
		reply(Dict.has_key?(position_grid, position))
	end

	defcall update_ant_position(agent, position), state: {agent_grid, position_grid, upper_bound} do
		Logger.info "Ant with pid #{inspect(agent)} is moving to the position #{inspect(position)}"
		agent_grid = HashDict.put(agent_grid, agent, position)
		position_grid = HashDict.put(position_grid, position, agent)
		set_and_reply({agent_grid, position_grid, upper_bound}, :ok)
	end

	def compute_upper_bound(agent_nr) do
		root_trunc = agent_nr |> :math.sqrt() |> :erlang.trunc
		2 * root_trunc 
	end

	def put_agents_on_grid(agent_grid, position_grid, [], _) do
		{agent_grid, position_grid}
	end

	#Definition 1: grid
	def put_agents_on_grid(agent_grid, position_grid, [agent | agents], upper_bound) do
		position = generate_position(agent_grid, upper_bound)
		Logger.info "Ant with pid #{inspect(agent)} is put on the position #{inspect(position)}"
		agent_grid = agent_grid 
			|> HashDict.put_new(agent, position)
		position_grid = position_grid
			|> HashDict.put_new(position, agent)
		put_agents_on_grid(agent_grid, position_grid, agents, upper_bound)
	end

	def generate_position(grid, upper_bound) do
		:random.seed(:erlang.now)
		x = :random.uniform(upper_bound) - 1
		y = :random.uniform(upper_bound) - 1
		values = HashDict.values(grid)
		if(Enum.member?(values, {x,y})) do
			generate_position(grid, upper_bound)
		else
			{x,y}
		end
	end
end