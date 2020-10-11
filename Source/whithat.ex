defmodule Whithat do
	@moduledoc """
	Documentation for `Whithat`.
	"""

	@doc """
	Hello world.

	## Examples

			iex> Whithat.hello()
			:world

	"""
	def hello do
		:world
	end

	@spec main() :: no_return()
	@spec main([binary()]) :: no_return()
	def main(args \\ [])

	def main(args) when is_list(args) do
		args
		# |> analyze
		|> Enum.fetch(0)
		|> case do
			{:ok, item} ->
				~r/^BV/
				|> Regex.match?(item)
				|> case do
					true ->
						{item |> Whithat.Bvid.decode(), item}

					false ->
						{item, item |> String.to_integer() |> Whithat.Bvid.encode()}
				end

			:error ->
				{:error, "No Enough Arguments"}
		end
		|> case do
			{:error, _} ->
				1

			{aid, bvid} ->
				args
				|> Enum.fetch(1)
				|> case do
					{:ok, item} ->
						aid
						|> Whithat.Video.BiliBili.getInfo()
						|> case do
							[title: title, pages: pages] when is_list(pages) ->
								IO.puts("Title: #{title}")

								pages
								|> case do
									[head | []] ->
										head
										|> Access.get("cid")
										|> case do
											cid ->
												IO.puts("Aid: #{aid}  Bvid: #{bvid}  Cid: #{cid}")
												head
										end

									[_ | _] ->
										IO.puts("Aid: #{aid}  Bvid: #{bvid}")
										IO.puts("Pages:")

										args
										|> Enum.fetch(2)
										|> case do
											{:ok, enum} ->
												enum

											:error ->
												"1-#{
													pages
													|> :erlang.length()
												}"
										end
										|> Theaserialzer.decode()
										|> case do
											enum ->
												pages
												|> Whithat.Enum.filter_with_index(fn item, i ->
													IO.puts(
														"-- #{item["part"]}  Cid: #{item["cid"]}" <>
															if((i + 1) in enum, do: " √", else: "")
													)

													(i + 1) in enum
												end)
										end
								end
								|> case do
									down ->
										IO.puts(
											"Quality: #{
												item
												|> case do
													116 -> "1080P60"
													112 -> "1080P+"
													80 -> "1080P"
													64 -> "720P"
													32 -> "480P"
													16 -> "360P"
												end
											}"
										)
										down
								end
						end

					:error ->
						1
				end
		end
		|> System.halt()
	end
end
