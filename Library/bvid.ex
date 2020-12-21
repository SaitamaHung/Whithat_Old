# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# This File if From Theopse (Self@theopse.org)
# Licensed under BSD-2-Caluse
# File:	bvid.ex (Whithat/Library/bvid.ex)
# Content:	Bilibili's Bvid Parser
# Copyright (c) 2020 Theopse Organization All rights reserved
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

defmodule Whithat.Bvid do
	@moduledoc """
	 BiliBili's Bvid Parser
	"""

	@doc """
	Parse Aid to Bvid
	(Bvid: https://www.bilibili.com/read/cv5167957)

	(This Function is to be changed)

	## Examples

			iex> Whithat.Bvid.encode(67719840)
			"BV1PJ411A727"
			iex> Whithat.Bvid.encode(795519616)
			"BV1kC4y1W71T"

	"""
	import Whithat

	@spec encode(integer()) :: :error | <<_::16, _::_*8>>
	def encode(aid) when is_integer(aid) do
		# The Magic String
		# You can see many Magic Item here as the origin auther hadn't give the expression
		# about them when the code have been written
		origin_magic_string = 'fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF'

		index = [11, 10, 3, 8, 4, 6]

		# The Magic Number
		num =
			aid
			# The Magic Number * 1
			|> Bitwise.bxor(1_7745_1812)
			# The Magic Number * 2
			|> Kernel.+(87_2834_8608)

		for {item, index} <- index |> Enum.with_index(), into: %{} do
			string =
				origin_magic_string
				|> Enum.fetch!(
					num
					|> Kernel./(
						:math.pow(58, index)
						|> floor
					)
					|> floor
					|> Integer.mod(58)
				)

			{item, string}
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
								?1

							5 ->
								?4

							7 ->
								?1

							9 ->
								?7

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
						[?B, ?V | list]
						|> String.Chars.List.to_string()
						|> return
				end
		end
	end

	@doc """
	Parse Bvid to Aid
	(Bvid: https://www.bilibili.com/read/cv5167957)

	## Examples

			iex> Whithat.Bvid.decode("BV1PJ411A727")
			67719840
			iex> Whithat.Bvid.decode("BV1kC4y1W71T")
			795519616

	"""

	@spec decode(bvid) :: :error | integer()
				when bvid: <<_::16, _::_*8>> | charlist()
	def decode(bvid) when is_binary(bvid), do: bvid |> String.to_charlist() |> decode

	def decode([?B, ?V | bvid]) when is_list(bvid) do
		# The Magic String
		# You can see many Magic Item here as the origin auther hadn't give the expression
		# about them when the code have been written
		origin_magic_string = 'fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF'

		table =
			origin_magic_string
			|> Enum.with_index()
			|> Map.new()

		table
		|> do_transform(bvid)
		|> Enum.sum()
		# Magic Number * 1
		|> Kernel.-(87_2834_8608)
		# Magic Number * 2
		|> Bitwise.bxor(1_7745_1812)
	end

	# = = = = = = = = = = = = = = = = = = = = =
	# 	Private SubFunction
	# = = = = = = = = = = = = = = = = = = = = =

	@spec do_transform(map(), charlist()) :: list(integer())
	defp do_transform(table, bvid) when is_map(table),
		do:
			bvid
			|> Enum.with_index()
			|> iterated(table, [])

	@spec iterated(list(), map(), list(integer())) :: list(integer())
	defp iterated([], _, result), do: result
	defp iterated([{head, 9} | tail], table, result), do: iterated(0, head, tail, table, result)
	defp iterated([{head, 8} | tail], table, result), do: iterated(1, head, tail, table, result)
	defp iterated([{head, 1} | tail], table, result), do: iterated(2, head, tail, table, result)
	defp iterated([{head, 6} | tail], table, result), do: iterated(3, head, tail, table, result)
	defp iterated([{head, 2} | tail], table, result), do: iterated(4, head, tail, table, result)
	defp iterated([{head, 4} | tail], table, result), do: iterated(5, head, tail, table, result)
	defp iterated([_ | tail], table, result), do: tail |> iterated(table, result)

	@spec iterated(integer(), char(), list(), map(), list()) :: list(integer())
	defp iterated(i, head, tail, table, result) do
		results =
			table
			|> Access.get(head)
			|> Kernel.*(
				:math.pow(58, i)
				|> floor
			)

		iterated(tail, table, [results | result])
	end
end
