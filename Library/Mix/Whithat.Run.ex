# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# This File if From Theopse (Self@theopse.org)
# Licensed under BSD-2-Caluse
# File:	Whithat.Run.ex (Whithat/Library/Mix/Tasks/Whithat.Run.ex)
# Content:	To make the "mix whithat.run" enable
# Copyright (c) 2020 Theopse Organization All rights reserved
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

defmodule Mix.Tasks.Whithat.Run do
	use Mix.Task

	@shortdoc "Run This Application"
	@spec run(any) :: no_return()
	def run(args) do
		# This will start our application
		Mix.Task.run("app.start")
		Whithat.CLI.main(args)
	end
end
