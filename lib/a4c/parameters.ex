defmodule A4C.Parameters do
	use ExActor.GenServer


	@doc """
	 state -> {s_x, s_y, alfa, lambda, theta, k_alfa, k_lambda}
	"""

	defstart start(state) do
		initial_state(state)
	end

	defcall get_s_x, state: {s_x, _, _, _, _, _, _}, do: reply(s_x)
	defcall get_s_y, state: {_, s_y, _, _, _, _, _}, do: reply(s_y)
	defcall get_alfa, state: {_, _, alfa, _, _, _, _}, do: reply(alfa)
	defcall get_lambda, state: {_, _, _, lambda, _, _, _}, do: reply(lambda)
	defcall get_theta, state: {_, _, _, _, theta, _, _}, do: reply(theta)
	defcall get_k_alfa, state: {_, _, _, _, _, k_alfa, _}, do: reply(k_alfa)
	defcall get_k_lambda, state: {_, _, _, _, _, _, k_lambda}, do: reply(k_lambda)

	defcast update_alfa(avg_fit, prev_avg_fit), state: {s_x, s_y, alfa, lambda, theta, k_alfa, k_lambda} do
		new_state({s_x, s_y, alfa - k_alfa*(avg_fit - prev_avg_fit), lambda, theta, k_alfa, k_lambda})
	end

	defcast update_lambda(avg_fit, logarithm), state: {s_x, s_y, alfa, _, theta, k_alfa, k_lambda} do
		new_state({s_x, s_y, alfa, 2 + (k_lambda/avg_fit)*logarithm, theta, k_alfa, k_lambda})
	end
end