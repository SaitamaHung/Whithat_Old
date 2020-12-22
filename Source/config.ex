# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# This File if From Theopse (Self@theopse.org)
# Licensed under BSD-2-Caluse
# File:	config.ex (Whithat/Source/config.ex)
# Content:	Whithat's Config File
# Copyright (c) 2020 Theopse Organization All rights reserved
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

defmodule Whithat.Config do
	def version, do: "Alpha 0.0.2"
	def full_version, do: [build: 2]
	def sessdata, do: "Put Your Sessdata Here"
	def ffmpeg, do: false
	def random_directory_string_size, do: 9
end
