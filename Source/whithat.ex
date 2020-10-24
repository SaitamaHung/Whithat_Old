# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# This File if From Theopse (Self@theopse.org)
# Licensed under BSD-2-Caluse
# File:	whithat.ex (Whithat/Source/whithat.ex)
# Content:	Whithat's Main(CLI) Source
# Copyright (c) 2020 Theopse Organization All rights reserved
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

defmodule Whithat do
	defmodule CLI do
		@moduledoc """
		Documentation for `Whithat`.
		"""

		defp streamDownload(link, aid, title) do
			"https://api.bilibili.com/x/web-interface/view?aid=#{aid}"
			|> case do
				uri ->
					[
						"User-Agent":
							"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:81.0) Gecko/20100101 Firefox/81.0",
						Accept: "*/*",
						"Accept-Language": "en-US,en;q=0.5",
						"Accept-Encoding": "gzip, deflate, br",
						Range: "bytes=0-",
						Referer: uri,
						Origin: "https://www.bilibili.com",
						Connection: "keep-alive"
					]
					|> case do
						headers ->
							[
								bars: ["=---", "-=--", "--=-", "---="],
								done: "=",
								left: "|",
								right: "|",
								bars_color: [],
								done_color: [],
								interval: 500,
								width: :auto
							]
							|> case do
								format ->
									fn format, count ->
										parts = format[:bars]
										index = rem(count, length(parts))
										part = Enum.at(parts, index)

										ProgressBar.BarFormatter.write(
											format,
											{part, format[:bars_color]},
											""
										)
									end
									|> case do
										render_frame ->
											IO.puts("#{title}:")

											Stream.resource(
												fn ->
													ProgressBar.AnimationServer.start(
														interval: format[:interval],
														render_frame: fn count -> render_frame.(format, count) end,
														render_done: fn -> ProgressBar.render(0, 1) end
													)

													{HTTPoison.get!(link, headers,
														 ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}],
														 recv_timeout: :infinity,
														 stream_to: self(),
														 async: :once
													 ), 0, 0}
												end,
												fn {%HTTPoison.AsyncResponse{id: id} = resp, size, downloaded} ->
													receive do
														%HTTPoison.AsyncStatus{id: ^id, code: _} ->
															# IO.inspect(code, label: "STATUS: ")
															ProgressBar.AnimationServer.stop()
															HTTPoison.stream_next(resp)
															{[], {resp, 0, 0}}

														%HTTPoison.AsyncHeaders{id: ^id, headers: headers} ->
															# IO.inspect(headers, label: "HEADERS: ")
															size =
																headers
																|> Enum.map(fn {start, next} -> {String.to_atom(start), next} end)
																|> Access.get(:"Content-Length")
																|> String.to_integer()

															ProgressBar.render(0, size, suffix: :bytes)
															HTTPoison.stream_next(resp)
															{[], {resp, size, 0}}

														%HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
															next = downloaded + byte_size(chunk)
															ProgressBar.render(next, size, suffix: :bytes)
															HTTPoison.stream_next(resp)
															{[chunk], {resp, size, next}}

														%HTTPoison.AsyncEnd{id: ^id} ->
															# IO.write([IO.ANSI.clear_line,"\r"])
															# ProgressBar.render(size,size,[left: [IO.ANSI.clear_line,"|"],right: ["|","\r"],suffix: :bytes])
															{:halt, {resp, size, size}}
													end
												end,
												fn {resp, _, _} ->
													IO.write([IO.ANSI.clear_line(), "\r"])
													:hackney.stop_async(resp.id)
												end
											)
									end
							end
					end
			end
		end

		defp download(parts, aid, title, subtitle),
			do:
				parts
				|> Enum.zip(subtitle)
				|> Enum.each(fn {item, subtitle} ->
					download(item, aid, title <> " --#{subtitle}")
				end)

		defp download(part, aid, title) do
			part
			|> case do
				[link] ->
					link
					|> streamDownload(aid, title)
					|> Stream.into(File.stream!("#{Regex.replace(~r/\//, title, ":")}.flv"))
					|> Stream.run()

				links ->
					links
					|> Enum.with_index()
					|> Enum.each(fn {item, i} ->
						item
						|> streamDownload(aid, title <> " \##{i + 1}.flv")
						|> Stream.into(File.stream!("#{Regex.replace(~r/\//, title, ":")} \##{i + 1}.flv"))
						|> Stream.run()
					end)
			end
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
													[head]
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
													|> Enum.with_index()
													|> Enum.filter(fn {item, i} ->
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
														"116" -> "1080P60"
														"112" -> "1080P+"
														"80" -> "1080P"
														"64" -> "720P"
														"32" -> "480P"
														"16" -> "360P"
													end
												}"
											)

											down
											|> Enum.map(fn item2 ->
												{
													item2["cid"],
													item2["page"],
													item2["part"]
												}
											end)
											|> case do
												[{cid, _, _}] ->
													aid
													|> Whithat.Video.BiliBili.getLinks(cid, item, Whithat.Config.sessdata())

												parts ->
													parts
													|> Enum.map(&(&1 |> elem(1)))
													|> Enum.join(",")
													|> case do
														pages ->
															IO.puts("Going to Download: #{pages}")
													end

													parts
													|> Enum.map(fn part ->
														part
														|> elem(0)
														|> case do
															cid ->
																aid
																|> Whithat.Video.BiliBili.getLinks(
																	cid,
																	item,
																	Whithat.Config.sessdata()
																)
														end
													end)
													|> case do
														links ->
															{links, parts |> Enum.map(&elem(&1, 2))}
													end
											end
											|> case do
												mono ->
													# IO.puts(
													# 	IO.ANSI.light_blue() <>
													# 		"Now Starting Downloading." <> IO.ANSI.default_color()
													# )
													format = [
														bar: "=",
														blank: "=",
														left: "#{IO.ANSI.light_blue()}=",
														right: "=#{IO.ANSI.default_color()}",
														percent: false
													]

													ProgressBar.render(1, 1, format)

													mono
													|> case do
														{links, subtitle} ->
															download(links, aid, title, subtitle)

														links ->
															download(links, aid, title)
													end
											end

											IO.puts("Downloaded Done!")
											0
									end
							end

						:error ->
							1
					end
			end
			|> System.halt()
		end
	end
end
