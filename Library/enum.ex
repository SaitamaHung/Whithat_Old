defmodule Whithat.Enum do
	@spec map_with_index(Enum.t(), (Enum.element(), integer() -> any())) :: list()
	def map_with_index(enumerable, fun) do
		enumerable
		|> :erlang.length()
		|> case do
			len ->
				for i <- 0..(len - 1),
						do:
							fun.(
								enumerable
								|> Enum.fetch(i)
								|> case do
									{:ok, item} -> item
									_ -> :error
								end,
								i
							)
		end
	end

	@spec filter_with_index(Enum.t(), (Enum.element(), integer() -> any())) :: list()
	def filter_with_index(enumerable, fun) do
		enumerable
		|> :erlang.length()
		|> case do
			len ->
				for i <- 0..(len - 1),
						fun.(
							enumerable
							|> Enum.fetch(i)
							|> case do
								{:ok, item} -> item
								_ -> :error
							end,
							i
						),
						do: enumerable |> Enum.fetch!(i)
		end
	end

	def each_with_index(enumerable, fun) do
		enumerable
		|> :erlang.length()
		|> case do
			len ->
				0..(len - 1)
				|> Enum.each(fn i ->
					fun.(
						enumerable
						|> Enum.fetch(i)
						|> case do
							{:ok, item} -> item
							_ -> :error
						end,
						i
					)
				end)
		end
	end
end
