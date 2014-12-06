defmodule A4C.DataTransformator do
	
	@result_folder "result/"
	@input_folder "input/"


	def normalize(data) do
		aux_list = data |> Enum.at(0) |> Enum.count |> initiate_auxiliary_list |> create_auxiliary_list(data)
		data 
		|> Enum.reduce([], fn data, list ->
			element = for i<-0..(Enum.count(data)-1) do
				value = Enum.at(data, i)
				{minimum, maximum} = Enum.at(aux_list, i)
				(value - minimum) / (maximum - minimum)
			end
			list ++ [element] 
		end)
	end

	def create_auxiliary_list(aux_list, []), do: aux_list

	def create_auxiliary_list(aux_list, [data | others]) do
		iterate_row(aux_list, data)
		|> create_auxiliary_list(others)
	end

	def iterate_row([], []), do: []

	def iterate_row([{minimum, maximum} | aux_list], [column | data]) do
		[{my_min(minimum, column), my_max(maximum, column)} | iterate_row(aux_list, data)]
	end

	def initiate_auxiliary_list(length) do
		for _<-1..length do
			{nil, nil}
		end
	end

	def write_result_to_csv(position_list, t_max) do
		data = position_list
		|> Enum.reduce([], fn {x, y, class}, list ->
			list ++ [[x, y, class]]
		end)
		 |> CSVLixir.write
		{{year,month,day},{hour,min,sec}} = :erlang.localtime()
		File.write!("#{@result_folder}result_#{t_max}_#{year}-#{month}-#{day}_#{hour}-#{min}-#{sec}.csv", data)
	end

	def read_data_from_csv(name) do
		File.read!("#{@input_folder}#{name}.csv")
		|> CSVLixir.read
		|> Enum.map(fn data -> Enum.map(data, fn value -> String.to_float(value) end) end)
	end

	#Computes maximum, nil not considered value
	def my_max(nil, value), do: value
	def my_max(value, nil), do: value
	def my_max(value1, value2), do: max(value1, value2)

	#Computes minimum, nil not considered value
	def my_min(nil, value), do: value
	def my_min(value, nil), do: value
	def my_min(value1, value2), do: min(value1, value2)
end