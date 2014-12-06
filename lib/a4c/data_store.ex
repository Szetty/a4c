defmodule A4C.DataStore do
	use ExActor.GenServer
	@doc """
		state -> data::HashDict(key=pid of ant, value=list of data)
	"""
	
	defstart start(data) do
		initial_state(data)
	end

	defcall get_data(ant), state: data do
		reply(data[ant])
	end

end