defmodule Exchange.ID do
  @name     __MODULE__
  @initial  0

  def start_link do
    Agent.start_link(fn -> @initial end, name: @name)
  end

  def get do
    Agent.get_and_update(@name, &do_get/1)
  end

  defp do_get(id), do: {id, id + 1}
end
