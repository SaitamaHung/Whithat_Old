defmodule Whithat.Bvid do
	@moduledoc """
	 BiliBili's Bvid Parser
	"""

	@doc """
	Parse Aid to Bvid

	## Examples

			iex> Whithat.Bvid.encode(67719840)
			"BV1PJ411A727"
			iex> Whithat.Bvid.encode(795519616)
			"BV1kC4y1W71T"

	"""
	@spec encode(integer()) :: :error | <<_::16, _::_*8>>
	def encode(aid) when is_integer(aid) do
		for i <- 0..5, into: %{} do
			[11, 10, 3, 8, 4, 6]
			|> Enum.fetch(i)
			|> case do
				{:ok, item} ->
					aid
					|> Bitwise.bxor(177_451_812)
					|> Kernel.+(8_728_348_608)
					|> case do
						num ->
							"fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF"
							|> String.at(
								num
								|> Kernel./(
									:math.pow(58, i)
									|> floor
								)
								|> floor
								|> Integer.mod(58)
							)
							|> case do
								string -> {item, string}
							end
					end

				:error ->
					:error
			end
		end
		|> case do
			origin ->
				origin
				|> Enum.all?(&Kernel.!=(&1, :error))
				|> case do
					true ->
						2..11
						|> Enum.map(fn
							2 ->
								1

							5 ->
								4

							7 ->
								1

							9 ->
								7

							i ->
								origin
								|> Access.get(i)
						end)

					false ->
						:error
				end
				|> case do
					:error ->
						:error

					list ->
						list
						|> Enum.join()
						|> case do
							result ->
								"BV"
								|> Kernel.<>(result)
						end
				end
		end
	end

	@doc """
	Parse Bvid to Aid

	## Examples

			iex> Whithat.Bvid.decode("BV1PJ411A727")
			67719840
			iex> Whithat.Bvid.decode("BV1kC4y1W71T")
			795519616

	"""
	@spec decode(<<_::16, _::_*8>>) :: :error | integer()
	def decode(bvid) when is_binary(bvid) do
		for n <- 0..57, into: %{} do
			"fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF"
			|> String.at(n)
			|> case do
				value -> {value, n}
			end
		end
		|> case do
			tr ->
				0..5
				|> Enum.map(fn i ->
					[11, 10, 3, 8, 4, 6]
					|> Enum.fetch(i)
					|> case do
						{:ok, item} ->
							tr
							|> Access.get(
								bvid
								|> String.at(item)
							)
							|> Kernel.*(
								:math.pow(58, i)
								|> floor
							)
					end
				end)
				|> Enum.sum()
				|> Kernel.-(8_728_348_608)
				|> Bitwise.bxor(177_451_812)
		end
	end
end
