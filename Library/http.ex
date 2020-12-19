# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# This File if From Theopse (Self@theopse.org)
# Licensed under BSD-2-Caluse
# File:	http.ex (Whithat/Library/http.ex)
# Content:	Universal Respond
# Copyright (c) 2020 Theopse Organization All rights reserved
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

defmodule Whithat.HTTP do
  @spec new :: pid
  def new do
    spawn(Whithat.HTTP, :loop, [])
  end
  @spec loop :: no_return
  def loop do
    receive do
      {from, ref, {:links, url, headers}} ->
        url
        |> HTTPoison.get(
			  headers,
        ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}])
        |> case do
          result ->
            send(from, {self(), ref, result})
        end
      {from, ref, {:json, json}} ->
        json
        |> Jason.decode()
        |> case do
           result ->
             send(from, {self(), ref, result})
         end
    end
    loop()
  end
end
