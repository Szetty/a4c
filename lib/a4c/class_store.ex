defmodule A4C.ClassStore do
	use ExActor.GenServer
	@doc """
		state -> classes::HashDict(key=pid of ant, value=class)
	"""
	
	defstart start(classes) do
		initial_state(classes)
	end

	defcall get_class(ant), state: classes do
		reply(classes[ant])
	end

	defcall update_class(ant, class), state: classes do
		new_classes = HashDict.put(classes, ant, class)
		set_and_reply(new_classes, :ok)
	end

end