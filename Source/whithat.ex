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

	@doc """
	Get the atom.

	## Examples

			iex> Whithat.test("a")
			:a

	"""
	@spec test(binary()) :: atom()
	def test(string) when is_binary(string),do: string |> String.to_atom()
end
