defmodule Whithat.MixProject do
	use Mix.Project

	def project do
		[
			app: :whithat,
			version: "0.1.0",
			elixir: "~> 1.10",
			# We reckon that Full-Name directory is better than Abbreviated-Name directory.
			# If it's not a good decision, tell us about that.
			# Anyway, you can directly and simply change directory's name.
			# By the way, in *nix environment, it's no matter between the upper letter and the lower.
			elixirc_paths: ["Library", "lib", "Source", "src"],
			erlc_paths: ["Source", "src"],
			xref: [exclude: Decimal],
			build_path: ".Build",
			deps_path: "Include",
			start_permanent: Mix.env() == :prod,
			deps: deps(),
			#compilers: [:make, :elixir, :app],
			escript: escript()
		]
	end

	# Run "mix help compile.app" to learn about applications.
	def application do
		[
			extra_applications: [:logger]
		]
	end

	# Run "mix help deps" to learn about dependencies.
	defp deps do
		[
			{:jason, "~> 1.2"},
			{:httpoison, "~> 1.6"},
			{:theaserialzer, "~> 0.1.0", hex: :theopse_serializer},
			{:progress_bar, "> 0.0.0"}
			# {:dep_from_hexpm, "~> 0.3.0"},
			# {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
		]
	end

	defp escript do
		[main_module: Whithat.CLI]
	end
end

defmodule Mix.Tasks.Compile.Make do
	def run(_) do
		System.cmd("clang", [
			"-undefined",
			"dynamic_lookup",
			"-dynamiclib",
			"Source/whithat.c",
			"-o",
			"Source/whithat.so",
			"-I",
			Whithat.Config.erl_path,
			"-lm"
		], stderr_to_stdout: true)
		System.cmd("mix", ["compile.erlang"], stderr_to_stdout: true)
		:ok
	end
end

