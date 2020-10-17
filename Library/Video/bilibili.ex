defmodule Whithat.Video.BiliBili do
	@moduledoc """
	BiliBili's API
	"""

	@doc """
	Using Private API to get video's link

	(Note: Up to 1080P.)

	(Note: It seems not able to work)

	"""
	@spec get_links_in_private(integer() | binary(), integer() | binary(), integer() | binary()) ::
					[binary()] | :error
	def get_links_in_private(aid, cid, quality) do
		"rbMCKn@KuamXWlPMoJGsKcbiJKUfkPF_8dABscJntvqhRSETg"
		|> String.to_charlist()
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
		|> case do
			{:ok, %HTTPoison.Response{body: body}} ->
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

			{:error, %HTTPoison.Error{}} ->
				:error
		end
	end

	@doc """
	Using Public API to get video's link, which needs sessdata.

	"""
	@spec getLinks(integer() | binary(), integer() | binary(), integer() | binary(), binary()) ::
					:error | [binary()]
	def getLinks(aid, cid, quality, sessdata), do: get_links(aid, cid, quality, sessdata)

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
	def get_cover(atom, number) do
		atom
		|> case do
			:aid ->
				"https://www.bilibili.com/video/av#{number}"

			:bvid ->
				"https://www.bilibili.com/video/#{number}"

			_ ->
				"https://www.bilibili.com/video/#{number}"
		end
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
end
