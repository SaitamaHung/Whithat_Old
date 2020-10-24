
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
