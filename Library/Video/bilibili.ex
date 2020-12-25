# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# This File if From Theopse (Self@theopse.org)
# Licensed under BSD-2-Caluse
# File:	bilibili.ex (Whithat/Library/Video/bilibili.ex)
# Content:	Library About Bilibili (www.bilibili.com)
# Copyright (c) 2020 Theopse Organization All rights reserved
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

defmodule Whithat.Video.BiliBili do
	@moduledoc """
	BiliBili's API
	"""

	@doc """
	Using Private API to get video's link

	(Note: Up to 1080P.)

	"""

	@type biliInfo :: %{
					binary() => integer(),
					binary() => %{
						binary() => integer(),
						binary() => integer(),
						binary() => integer()
					},
					binary() => integer(),
					binary() => binary(),
					binary() => integer(),
					binary() => binary(),
					binary() => binary(),
					binary() => binary()
				}

	@spec get_links_in_private(integer() | binary(), integer() | binary(), integer() | binary()) ::
					[binary()] | :error
	def get_links_in_private(aid, cid, quality) do
		'rbMCKn@KuamXWlPMoJGsKcbiJKUfkPF_8dABscJntvqhRSETg'
		|> Enum.reverse()
		|> Enum.map(&(&1 + 2))
		|> to_string
		|> String.split(":")
		|> case do
			[appkey, sec] ->
				"appkey=#{appkey}&cid=#{cid}&otype=json&qn=#{quality}&quality=#{quality}&type="
				|> case do
					params ->
						:crypto.hash(:md5, params <> sec)
						|> Base.encode16(case: :lower)
						|> case do
							chksum -> "https://interface.bilibili.com/v2/playurl?#{params}&sign=#{chksum}"
						end
				end
		end
		|> HTTPoison.get(
			[
				Referer: "https://api.bilibili.com/x/web-interface/view?aid=#{aid}",
				"User-Agent":
					"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:80.0) Gecko/20100101 Firefox/80.0"
			],
			ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}]
		)
		|> case do
			{:ok, %HTTPoison.Response{body: body}} ->
				body
				|> Jason.decode()
				|> case do
					{:ok, json} ->
						json
						|> Access.get("durl")
						|> Enum.map(&Access.get(&1, "url"))

					{:error, %Jason.DecodeError{}} ->
						:error
				end

			{:error, %HTTPoison.Error{}} ->
				:error
		end
	end

	@doc """
	Using Private API to get video's link
	(Note: Up to 1080P.)
	(Note: It seems not able to work)


	"""
	@spec getLinksInPrivate(integer() | binary(), integer() | binary(), integer() | binary()) ::
					[binary()] | :error
	def getLinksInPrivate(aid, cid, quality), do: get_links_in_private(aid, cid, quality)

	@doc """
	Using Public API to get video's link, which needs sessdata.

	"""
	@spec get_links(integer() | binary(), integer() | binary(), integer() | binary(), binary()) ::
					:error | [binary()]
	def get_links(aid, cid, quality, sessdata) do
		server = spawn(Whithat.HTTP, :loop, [])
		ref = :erlang.make_ref()

		send(
			server,
			{self(), ref,
			 {:links, "https://api.bilibili.com/x/player/playurl?cid=#{cid}&avid=#{aid}&qn=#{quality}",
				[
					"User-Agent":
						"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:80.0) Gecko/20100101 Firefox/80.0",
					Cookie: "SESSDATA=#{sessdata}",
					Host: "api.bilibili.com"
				]}}
		)

		receive do
			{^server, ^ref, {:ok, %HTTPoison.Response{body: body}}} ->
				send(server, {self(), ref, {:json, body}})

				receive do
					{^server, ^ref, {:ok, json}} ->
						json
						|> Access.get("data")
						|> Access.get("durl")
						|> Enum.map(&Access.get(&1, "url"))

					{^server, ^ref, {:error, %Jason.DecodeError{}}} ->
						:error
				end

			{^server, ^ref, {:error, %HTTPoison.Error{}}} ->
				:error
		end
	end

	@doc """
	Using Public API to get video's link, which needs sessdata.

	"""
	@spec getLinks(integer() | binary(), integer() | binary(), integer() | binary(), binary()) ::
					:error | [binary()]
	def getLinks(aid, cid, quality, sessdata), do: get_links(aid, cid, quality, sessdata)

	@spec async_get_links(
					pid,
					integer() | binary(),
					integer() | binary(),
					integer() | binary(),
					binary()
				) ::
					:error | [binary()]
	def async_get_links(pid, aid, cid, quality, sessdata) do
		pid
		|> send(
			{self(),
			 {:links, "https://api.bilibili.com/x/player/playurl?cid=#{cid}&avid=#{aid}&qn=#{quality}",
				[
					"User-Agent":
						"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:80.0) Gecko/20100101 Firefox/80.0",
					Cookie: "SESSDATA=#{sessdata}",
					Host: "api.bilibili.com"
				]}}
		)

		receive do
			{from, {:ok, %HTTPoison.Response{body: body}}} when from == pid ->
				body
				|> Jason.decode()
				|> case do
					{:ok, json} ->
						json
						|> Access.get("data")
						|> Access.get("durl")
						|> Enum.map(&Access.get(&1, "url"))

					{:error, %Jason.DecodeError{}} ->
						:error
				end

			{from, {:error, %HTTPoison.Error{}}} when from == pid ->
				:error
		end
	end

	@spec asyncGetLinks(
					pid,
					integer() | binary(),
					integer() | binary(),
					integer() | binary(),
					binary()
				) ::
					:error | [binary()]
	def asyncGetLinks(pid, aid, cid, quality, sessdata),
		do: async_get_links(pid, aid, cid, quality, sessdata)

	@doc """
	Get Video's Info by AID API

	## Examples

			iex> Whithat.Video.BiliBili.get_info(926757974)
			[
				title: "「コしロ」[Remix] たまシいノし",
				pages: [
					%{
						"cid" => 226774029,
						"dimension" => %{"height" => 1080, "rotate" => 0, "width" => 1920},
						"duration" => 207,
						"from" => "vupload",
						"page" => 1,
						"part" => "たまシいノし",
						"vid" => "",
						"weblink" => ""
					}
				]
			]

	"""
	@spec get_info(integer() | binary()) ::
					:error
					| [
							title: nil | binary(),
							pages: [
								nil
								| info
							]
						]
				when info: biliInfo()
	def get_info(aid) do
		"https://api.bilibili.com/x/web-interface/view?aid=#{aid}"
		|> HTTPoison.get(
			[
				"User-Agent":
					"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:80.0) Gecko/20100101 Firefox/80.0"
			],
			ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}]
		)
		|> case do
			{:ok, %HTTPoison.Response{body: body}} ->
				body
				|> Jason.decode()
				|> case do
					{:ok, json} ->
						json
						|> Access.get("data")
						|> case do
							data ->
								[
									title:
										data
										|> Access.get("title"),
									pages:
										data
										|> Access.get("pages")
								]
						end

					_ ->
						:error
				end

			_ ->
				:error
		end
	end

	@doc """
	Get Video's Info by AID API

	## Examples

			iex> Whithat.Video.BiliBili.getInfo(926757974)
			[
				title: "「コしロ」[Remix] たまシいノし",
				pages: [
					%{
						"cid" => 226774029,
						"dimension" => %{"height" => 1080, "rotate" => 0, "width" => 1920},
						"duration" => 207,
						"from" => "vupload",
						"page" => 1,
						"part" => "たまシいノし",
						"vid" => "",
						"weblink" => ""
					}
				]
			]

	"""
	@spec getInfo(integer() | binary()) ::
					:error
					| [
							title: nil | binary(),
							pages: [
								nil
								| %{
										binary() => integer(),
										binary() => %{
											binary() => integer(),
											binary() => integer(),
											binary() => integer()
										},
										binary() => integer(),
										binary() => binary(),
										binary() => integer(),
										binary() => binary(),
										binary() => binary(),
										binary() => binary()
									}
							]
						]
	def getInfo(aid), do: get_info(aid)

	@doc """
	Get Video's Cover

	Note: From the pages.
	"""
	@spec get_cover(:aid | :bvid, binary()) :: :error | binary()
	def get_cover(:aid, number), do: get_cover("https://www.bilibili.com/video/av#{number}")
	def get_cover(:bvid, number), do: get_cover("https://www.bilibili.com/video/#{number}")

	defp get_cover(url) do
		url
		|> HTTPoison.get(
			[
				"User-Agent":
					"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:80.0) Gecko/20100101 Firefox/80.0"
			],
			ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}]
		)
		|> case do
			{:ok, %HTTPoison.Response{body: body}} ->
				~r/<script>window.__INITIAL_STATE__=(?<html>.*?);.+<\/script>/
				|> Regex.named_captures(
					body
					|> :zlib.gunzip()
				)
				|> Access.get("html")
				|> Jason.decode()
				|> case do
					{:ok, json} ->
						json
						|> Access.get("videoData")
						|> Access.get("pic")
						|> HTTPoison.get(
							[
								"User-Agent":
									"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:80.0) Gecko/20100101 Firefox/80.0"
							],
							ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}]
						)
						|> case do
							{:ok, %HTTPoison.Response{body: body}} -> body
						end

					{:error, %Jason.DecodeError{}} ->
						:error
				end

			{:error, %HTTPoison.Error{}} ->
				:error
		end
	end

	@doc """
	Get Video's Cover

	Note: From the pages.
	"""
	@spec getCover(:aid | :bvid, binary()) :: :error | binary()
	def getCover(atom, number), do: get_cover(atom, number)

	@doc """
	Using Public API to get video's Current Quality, needing sessdata.

	"""
	@spec get_current_quality(
					integer() | binary(),
					integer() | binary(),
					integer() | binary(),
					binary()
				) ::
					:error | integer()
	def get_current_quality(aid, cid, quality, sessdata) do
		"https://api.bilibili.com/x/player/playurl?cid=#{cid}&avid=#{aid}&qn=#{quality}"
		|> HTTPoison.get(
			[
				"User-Agent":
					"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:80.0) Gecko/20100101 Firefox/80.0",
				Cookie: "SESSDATA=#{sessdata}",
				Host: "api.bilibili.com"
			],
			ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}]
		)
		|> get_current_quality()
	end

	defp get_current_quality({:ok, %HTTPoison.Response{body: body}}) do
		body
		|> Jason.decode()
		|> case do
			{:ok, json} ->
				json
				|> Access.get("data")
				|> Access.get("quality")

			{:error, %Jason.DecodeError{}} ->
				:error
		end
	end

	defp get_current_quality({:error, %HTTPoison.Error{}}), do: :error

	@doc """
	Using Public API to get video's Current Quality, needing sessdata.

	"""
	@spec getCurrentQuality(
					integer() | binary(),
					integer() | binary(),
					integer() | binary(),
					binary()
				) ::
					:error | integer()
	def getCurrentQuality(aid, cid, quality, sessdata),
		do: get_current_quality(aid, cid, quality, sessdata)

	@type bangumi_info ::	%{
			                     name: binary(),
			                     videoList: [
				                     %{
					                     :aid => integer() | binary(),
					                     :cid => integer() | binary(),
					                     :title => binary(),
					                     :longTitle => binary()
				                     }
			                     ]
		                     }

	@spec get_bangumi_info(binary()) :: bangumi_info()
	def get_bangumi_info(ep), do: get_bangumi_info(:ep, ep)
	# def get_bangumi_info(ss), do: get_bangumi_info(:ss, ss)

	@spec get_bangumi_info(:ep | :ss, binary() | integer()) :: bangumi_info()
	def get_bangumi_info(:ep, ep),
		do: get_bangumi_info(:final, "https://www.bilibili.com/bangumi/play/ep#{ep}", nil)

	def get_bangumi_info(:ss, ss),
		do: get_bangumi_info(:final, "https://www.bilibili.com/bangumi/play/ss#{ss}", nil)

	defp get_bangumi_info(:final, url, _) do
		re = ~r/<script>window.__INITIAL_STATE__=(?<html>.*?);.+<\/script>/

		headers = [
			"User-Agent":
				"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
		]

		url
		|> HTTPoison.get(headers, ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}])
		|> case do
			{:ok, %HTTPoison.Response{body: body}} ->
				html =
					body
					|> :zlib.gunzip()

				re
				|> Regex.named_captures(html)
				|> Access.get("html")
				|> Jason.decode()
				|> case do
					{:ok, json} ->
						result = %{:name => json["mediaInfo"]["title"]}

						Map.put(
							result,
							:videoList,
							Enum.map(json["epList"], fn item ->
								%{
									:aid => item["aid"],
									:cid => item["cid"],
									:title => item["title"],
									:longTitle => item["longTitle"]
								}
							end)
						)
				end
		end
	end

	#
	#
	#
end
