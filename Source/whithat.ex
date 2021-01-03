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

	def tap(item, fun) do
		fun.(item)
		item
	end

	# Just for fun
	# Theopse/Standard
	@spec list?(any) :: {:__block__ | {:., [], [:erlang | :is_list, ...]}, [], [...]}
	defguard list?(term) when is_list(term)

	@spec tuple?(any) :: {:__block__ | {:., [], [:erlang | :is_tuple, ...]}, [], [...]}
	defguard tuple?(term) when is_tuple(term)

	@spec atom?(any) :: {:__block__ | {:., [], [:erlang | :is_atom, ...]}, [], [...]}
	defguard atom?(term) when is_atom(term)

	@spec binary?(any) :: {:__block__ | {:., [], [:erlang | :is_binary, ...]}, [], [...]}
	defguard binary?(term) when is_binary(term)

	@spec string?(any) :: {:__block__ | {:., [], [:erlang | :is_binary, ...]}, [], [...]}
	defguard string?(term) when is_binary(term)
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
				Map.put(map, key, value)
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

	defp bangumi_download({video_list, name, quality}, tmp_string) do
		#IO.puts(
		#	"[#{IO.ANSI.red()}Note#{IO.ANSI.default_color()}] \nThis Method is EAP Version. If There is Any Problems, Please let me now"
		#)

		#IO.puts("(You need a sessdata since by using private api it won't return the links")


		video_list
		|> Enum.each(fn item ->
			aid = item[:aid]
			cid = item[:cid]
			long_title = item[:longTitle]
			title = item[:title]

		IO.puts(
				"Target Quality: #{
					quality
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

			format = [
				bar: "=",
				blank: "=",
				left: "#{IO.ANSI.light_blue()}=",
				right: "=#{IO.ANSI.default_color()}",
				percent: false
			]

			ProgressBar.render(1, 1, format)

		links = Whithat.Video.BiliBili.get_links(aid, cid, quality, Whithat.Config.sessdata())


			# tmp_string =
			# 	"#{
			# 		NaiveDateTime.local_now()
			# 		|> Time.to_string()
			# 		|> String.split(":")
			# 		|> Enum.join()
			# 		|> Base.encode64(case: :lower)
			# 	}#{
			# 		begin do
			# 			length = Whithat.Config.random_directory_string_size()
			# 			# :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
			# 			num = ?0..?9
			# 			big = ?A..?Z
			# 			little = ?a..?z

			# 			[num, big, little]
			# 			|> Stream.iterate(& &1)
			# 			|> Stream.take(length)
			# 			|> Stream.map(&Enum.random/1)
			# 			|> Enum.map(&Enum.random/1)
			# 		end
			# 	}"

			# File.mkdir_p("#{System.tmp_dir!()}Whithat/#{tmp_string}/")

			download(links, aid, "[#{name}]#{long_title} --#{title}", tmp_string)

			File.rmdir!("#{System.tmp_dir!()}Whithat/#{tmp_string}/")
			IO.puts("Downloaded Done!")
			0
		end)
	end

	defp bangumi_info(args, otp) do
		ss? =
			otp
			|> Access.get(:ss)

		[id, quality | other] = args

		pages =
			other
			|> case do
				[pages | _] -> pages
				[] -> :all
			end

		info = Whithat.Video.BiliBili.get_bangumi_info(if(ss?, do: :ss, else: :ep), id)

		name = info[:name]

		IO.puts("Name: #{name}")
		IO.puts("Pages:")

		video_list =
			if pages == :all do
				info
				|> Access.get(:videoList)
			else
				range = Theaserialzer.decode(pages)

				info
				|> Access.get(:videoList)
				|> Stream.with_index()
				|> Enum.filter(fn {item, index} ->
					IO.puts(
						"--#{item[:title]} #{item[:longTitle]}  Aid: #{item[:aid]} Cid: #{item[:cid]}" <>
						if((index + 1) in range, do: " √", else: "")
					)

					(index + 1) in range
				end)
				|> Stream.map(fn {item, _} -> item end)
			end

		{video_list, name, quality}
	end

	@spec main([binary()]) :: no_return()

	def main(["clean"]) do
		System.cmd("rm",["-rf","#{System.tmp_dir!()}Whithat/"])
	end

	# Bangumi

	# def main(["bangumi", "--ss", ss, quality]), do: main(["bangumi", "--ss", ss, quality, :all])
	# def main(["bangumi", ep, quality]), do: main(["bangumi", ep, quality, :all])

	def main(["bangumi" | args]) do
		{opt, args, _error} =
			args
			|> OptionParser.parse(strict: [ss: :boolean])

		tmp = make_tmp_folder()

		args
		|> bangumi_info(opt)
		|> bangumi_download(tmp)
		|> System.halt()
	end

	# def main(["bangumi", :final, info, quality, :all]) do
	# 	name = info[:name]

	# 	info
	# 	|> Access.get(:videoList)
	# 	|> bangumi_download(name, quality)
	# end

	# def main(["bangumi", :final, info, quality, pages]) do
	# 	page = Theaserialzer.decode(pages)

	# 	name = info[:name]

	# 	info
	# 	|> Access.get(:videoList)
	# 	|> Stream.with_index()
	# 	|> Stream.filter(fn {_, index} ->
	# 		(index + 1) in page
	# 	end)
	# 	|> Stream.map(fn {item, _} -> item end)
	# 	|> bangumi_download(name, quality)
	# end

	# def main(["bangumi", "--ss", ss, quality, pages | _]) do
	# 	info = Whithat.Video.BiliBili.get_bangumi_info(:ss, ss)
	# 	main(["bangumi", :final, info, quality, pages])
	# end

	# def main(["bangumi", ep, quality, pages | _]) do
	# 	# IO.inspect(ep)
	# 	info = Whithat.Video.BiliBili.get_bangumi_info(:ep, ep)
	# 	main(["bangumi", :final, info, quality, pages])
	# end

	# def main(["bangumi", "ep", ep, quality, pages]) do
	# 	info = Whithat.Video.BiliBili.get_bangumi_info(ep)
	# 	main(["bangumi", :final, info, quality, pages])
	# end

	# Origin

	# def main([id, quality]), do: main([id, quality, :all])

	# def main([id, quality, pages]) do
	# 	cond do
	# 		id =~ ~r/^BV/ ->
	# 			bvid = id
	# 			aid = Whithat.Bvid.decode(bvid)
	# 			{aid, bvid}

	# 		true ->
	# 			aid = id
	# 			bvid = Whithat.Bvid.encode(aid)
	# 			{aid, bvid}
	# 	end
	# 	|> get_info(quality, pages)
	# end

	def main(args) when is_list(args) do
		File.mkdir_p("#{System.tmp_dir!()}Whithat/")

		tmp_string =
			"#{
				NaiveDateTime.local_now()
				|> Time.to_string()
				|> String.split(":")
				|> Enum.join()
				|> Base.encode64(case: :lower)
			}#{
				begin do
					length = Whithat.Config.random_directory_string_size()

					num = ?0..?9
					big = ?A..?Z
					little = ?a..?z

					[num, big, little]
					|> Stream.iterate(& &1)
					|> Stream.take(length)
					|> Stream.map(&Enum.random/1)
					|> Enum.map(&Enum.random/1)
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

	#
	#
	#

	defp make_tmp_folder() do
		tmp_string =
			"#{
				NaiveDateTime.local_now()
				|> Time.to_string()
				|> String.split(":")
				|> Enum.join()
				|> Base.encode64(case: :lower)
			}#{tmp_string(Whithat.Config.random_directory_string_size())}"

		File.mkdir_p("#{System.tmp_dir!()}Whithat/#{tmp_string}/")

		tmp_string
	end

	defp times(0, _), do: :ok

	defp times(time, fun) do
		fun.()
		times(time - 1, fun)
	end

	defp tmp_string(len) do
		range =
			?0..?z
			|> Enum.filter(&(&1 not in 58..64 and &1 not in 91..96))

		1..len
		|> Enum.map(fn _ ->
			range
			|> Enum.random
		end)
		|> to_string
	end

	defp get_info({aid, bvid}, quality, pages) do
		[title: title, pages: video_list] = Whithat.Video.BiliBili.getInfo(aid)

		IO.puts("Title: #{title}")

		{:ok, agent} = Agent.start_link(fn -> false end)

		filter_video_list =
			video_list
			|> check_single_pages(aid, bvid, agent, pages)

		is_single = Agent.get(agent, & &1)
	end

	defp check_single_pages(list = [single | []], aid, bvid, _, _) do
		cid =
			single
			|> Access.get("cid")

		IO.puts("Aid: #{aid}  Bvid: #{bvid}  Cid: #{cid}")

		list
	end

	defp check_single_pages(list, aid, bvid, agent, pages) do
		agent
		|> Agent.update(fn _ -> true end)

		IO.puts("Aid: #{aid}  Bvid: #{bvid}")
		IO.puts("Pages:")

		range =
			pages
			|> case do
				:all ->
					"1-#{
						list
						|> :erlang.length()
					}"

				_ ->
					pages
			end
			|> Theaserialzer.decode()

		range
		|> Enum.with_index()
		|> Enum.filter(fn {item, i} ->
			bool = (i + 1) in range

			IO.puts(
				"-- #{item["part"]}  Cid: #{item["cid"]}" <>
					if(bool, do: " √", else: "")
			)

			# 	env_set(env, "pages", true)

			bool
		end)
		|> Enum.map(fn {value, _} -> value end)
	end
end
