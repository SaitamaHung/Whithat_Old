# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# This File is From Theopse (Self@theopse.org)
# Licensed under BSD-2-Caluse
# File:	whithat.ex (Whithat/Source/whithat.ex)
# Content:	Whithat's Main(CLI) Source
# Copyright (c) 2020 Theopse Organization All rights reserved
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

defmodule Whithat do
	# /-/
	defmacro return(expression), do: expression
	defmacro begin(do: block), do: block
end

# QWQ
defmodule Whithat.CLI do
	@moduledoc """
	Documentation for `Whithat`.
	"""
	import Whithat

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

	defp download(parts, aid, title, subtitle, tmp_string),
		do:
			parts
			|> Enum.zip(subtitle)
			|> Enum.each(fn {item, subtitle} ->
				download(item, aid, title <> " --#{subtitle}", tmp_string)
			end)

	defp download([link], aid, title, tmp_string) do
		link
		|> streamDownload(aid, title)
		|> Stream.into(
			File.stream!(
				"#{System.tmp_dir!()}Whithat/#{tmp_string}/#{Regex.replace(~r/\//, title, ":")}.flv"
			)
		)
		|> Stream.run()

		System.cmd("mv", [
			"#{System.tmp_dir!()}Whithat/#{tmp_string}/#{Regex.replace(~r/\//, title, ":")}.flv",
			"./"
		])

		# File.rm!("#{System.tmp_dir!}Whithat/#{tmp_string}/#{Regex.replace(~r/\//, title, ":")}.flv")
	end

	defp download(links, aid, title, tmp_string) do
		links
		|> Enum.with_index()
		|> Enum.each(fn {item, i} ->
			item
			|> streamDownload(aid, title <> " \##{i + 1}.flv")
			|> Stream.into(
				File.stream!(
					"#{System.tmp_dir!()}Whithat/#{tmp_string}/#{Regex.replace(~r/\//, title, ":")} \##{
						i + 1
					}.flv"
				)
			)
			|> Stream.run()

			System.cmd("mv", [
				"#{System.tmp_dir!()}Whithat/#{tmp_string}/#{Regex.replace(~r/\//, title, ":")} \##{i + 1}.flv",
				"./"
			])

			# File.rm!("#{System.tmp_dir!}Whithat/#{tmp_string}/#{Regex.replace(~r/\//, title, ":")}.flv")
		end)
	end

	def __spawn__(map, owner, ref) do
		receive do
			{^owner, ^ref, :get, key} ->
				send(owner, {self(), ref, map[key]})
				__spawn__(map, owner, ref)

			{^owner, ^ref, :set, key, value} ->
				map
				|> Map.has_key?(key)
				|> case do
					true ->
						Map.replace(map, key, value)

					false ->
						Map.put_new(map, key, value)
				end
				|> case do
					result ->
						send(owner, {self(), ref, true})
						__spawn__(result, owner, ref)
				end
		end
	end

	defp new_env do
		ref = make_ref()
		{:env, spawn(Whithat.CLI, :__spawn__, [Map.new(), self(), ref]), ref}
	end

	defp env_get({:env, pid, ref}, key) do
		self = self()
		send(pid, {self(), ref, :get, key})

		receive do
			{^self, ^ref, result} ->
				result
		end
	end

	defp env_set({:env, pid, ref}, key, value) do
		self = self()
		send(pid, {self(), ref, :set, key, value})

		receive do
			{^self, ^ref, true} ->
				true
		end
	end

	defp bangumi_download(video_list, name, quality) do
		IO.puts(
			"[#{IO.ANSI.red()}Note#{IO.ANSI.default_color()}] \nThis Method is EAP Version. If There is Any Problems, Please let me now"
		)

		IO.puts("(You need a sessdata since by using private api it won't return the links")

		video_list
		|> Enum.each(fn item ->
			aid = item[:aid]
			cid = item[:cid]
			long_title = item[:longTitle]
			title = item[:title]

			links = Whithat.Video.BiliBili.get_links(aid, cid, quality, Whithat.Config.sessdata())

			tmp_string =
				"#{NaiveDateTime.local_now() |> Time.to_string() |> String.split(":") |> Enum.join()}#{
					begin do
						num = ?0..?9
						big = ?A..?Z
						little = ?a..?z

						[num, big, little]
						|> Enum.take_random(Whithat.Config.random_directory_string_size())
						|> Enum.map(&Enum.take_random(&1, 1))
						|> List.flatten()
						|> to_string
					end
				}"

			File.mkdir_p("#{System.tmp_dir!()}Whithat/#{tmp_string}/")

			download(links, aid, "[#{name}]#{long_title} --#{title}", tmp_string)

			File.rmdir!("#{System.tmp_dir!()}Whithat/#{tmp_string}/")
			0
		end)
	end

	# @spec main() :: no_return()
	@spec main([binary()]) :: no_return()
	# def main(args \\ [])
	def main(["clean"]) do
		File.rmdir("#{System.tmp_dir!()}Whithat/")
	end

	def main(["bangumi", ep, quality]), do: main(["bangumi", "ep", ep, quality])
	def main(["bangumi", "ep", ep, quality]) do
		info = Whithat.Video.BiliBili.get_bangumi_info(ep)
		main(["bangumi", :final, info, quality])
	end
	def main(["bangumi", "ss", ss, quality]) do
		info = Whithat.Video.BiliBili.get_bangumi_info(:ss, ss)
		main(["bangumi", :final, info, quality])
	end
	def main(["bangumi", :final, info, quality]) do
		name = info[:name]

		info
		|> Access.get(:videoList)
		|> bangumi_download(name, quality)
	end

	def main(["bangumi", ep, quality, pages]), do: main(["bangumi", "ep", ep, quality, pages])

	def main(["bangumi", "ep", ep, quality, pages]) do
		info = Whithat.Video.BiliBili.get_bangumi_info(ep)
		main(["bangumi", :final, info, quality, pages])
	end
	def main(["bangumi", "ss", ss, quality, pages]) do
		info = Whithat.Video.BiliBili.get_bangumi_info(:ss, ss)
		main(["bangumi", :final, info, quality, pages])
	end
	def main(["bangumi", :final, info, quality, pages]) do
		page = Theaserialzer.decode(pages)

		name = info[:name]

		info
		|> Access.get(:videoList)
		|> Stream.with_index()
		|> Stream.filter(fn {_, index} ->
			index+1 in page
		end)
		|> Stream.map(fn {item, _} -> item end)
		|> bangumi_download(name, quality)
	end

	def main(args) when is_list(args) do
		File.mkdir_p("#{System.tmp_dir!()}Whithat/")

		tmp_string =
			"#{NaiveDateTime.local_now() |> Time.to_string() |> String.split(":") |> Enum.join()}#{
				begin do
					num = ?0..?9
					big = ?A..?Z
					little = ?a..?z

					[num, big, little]
					|> Enum.take_random(Whithat.Config.random_directory_string_size())
					|> Enum.map(&Enum.take_random(&1, 1))
					|> List.flatten()
					|> to_string
				end
			}"

		File.mkdir_p("#{System.tmp_dir!()}Whithat/#{tmp_string}/")
		env = new_env()

		args
		# |> analyze	Before Next Version, Analyze won't be used
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

													# 	env_set(env, "pages", true)

													(i + 1) in enum
												end)
												|> Enum.map(
													&case(&1) do
														{item, _} ->
															item
													end
												)
										end
								end
								|> case do
									down ->
										IO.puts(
											"Target Quality: #{
												item
												|> case do
													"120" -> "4K"
													"116" -> "1080P60"
													"112" -> "1080P+"
													"80" -> "1080P"
													"74" -> "720P60"
													"64" -> "720P"
													"48" -> "720P"
													"32" -> "480P"
													"16" -> "360P"
													_ -> "Unknown"
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
												# aid
												# |> Whithat.Video.BiliBili.getLinks(cid, item, Whithat.Config.sessdata())
												Whithat.Config.sessdata()
												|> case do
													"Put Your Sessdata Here" ->
														aid
														|> Whithat.Video.BiliBili.getLinksInPrivate(cid, item)

													_ ->
														aid
														|> Whithat.Video.BiliBili.getLinks(
															cid,
															item,
															Whithat.Config.sessdata()
														)
												end

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
													|> case do
														{cid, _, _} ->
															sessdata = Whithat.Config.sessdata()

															sessdata
															|> case do
																"Put Your Sessdata Here" ->
																	aid
																	|> Whithat.Video.BiliBili.getLinksInPrivate(cid, item)

																_ ->
																	aid
																	|> Whithat.Video.BiliBili.getLinks(cid, item, sessdata)
															end
													end
												end)
												|> case do
													links ->
														{links,
														 parts
														 |> Enum.map(
															 &case(&1) do
																 {_, _, part} -> part
															 end
														 )}
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
														download(links, aid, title, subtitle, tmp_string)

													links ->
														download(links, aid, title, tmp_string)
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
		|> case do
			0 ->
				File.rmdir!("#{System.tmp_dir!()}Whithat/#{tmp_string}/")
				0

			1 ->
				IO.puts(IO.ANSI.red() <> "No Enough Arguments!" <> IO.ANSI.default_color())
				1
		end
		|> System.halt()
	end
end
