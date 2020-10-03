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
            Whithat.Bvid.decode(item)

          false ->
            item
        end

      :error ->
        {:error, "No Enough Arguments"}
    end
    |> case do
      {:error, _} ->
        1

      aid ->
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
                    IO.puts(
                      "Aid: #{aid}  Bvid: #{Whithat.Bvid.encode(aid)}  Cid: #{
                        head |> Access.get("cid")
                      }"
                    )

                  [_ | _] ->
                    IO.puts("Aid: #{aid}  Bvid: #{Whithat.Bvid.encode(aid)}")
                    IO.puts("Pages:")

                    pages
                    |> Enum.each(fn item ->
                      IO.puts("-- #{item["part"]}  Cid: #{item["cid"]}")
                    end)
                end

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

								args
            end

          :error ->
            1
        end
    end
    |> System.halt()
  end
end
