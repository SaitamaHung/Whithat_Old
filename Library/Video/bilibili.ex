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
  
  

end
