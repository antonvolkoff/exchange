defmodule Exchange.Engine do
  use GenServer

  @state {[], []}

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def add(engine, order) do
    GenServer.cast(engine, {:add, order})
  end

  def book(engine) do
    GenServer.call(engine, :book)
  end

  ## Callbacks #################################################################

  def init(:ok) do
    {:ok, {[], []}}
  end

  def handle_cast({:add, order}, book) do
    {:noreply, add_order(book, order)}
  end

  def handle_call(:book, _, book) do
    {:reply, book, book}
  end

  ##

  defp add_order({buy, sell}, %{side: :buy} = order) do
    entry =
      buy
      |> find_entry(order)
      |> put_order(order)

    buy =
      buy
      |> put_entry(entry)
      |> Enum.sort(fn({p1, _}, {p2, _}) -> p1 > p2 end)

    {buy, sell}
  end

  defp add_order({buy, sell}, %{side: :sell} = order) do
    entry =
      sell
      |> find_entry(order)
      |> put_order(order)

    sell =
      sell
      |> put_entry(entry)
      |> Enum.sort(fn({p1, _}, {p2, _}) -> p1 < p2 end)

    {buy, sell}
  end

  defp find_entry(entries, %{price: price}) do
    List.keyfind(entries, price, 0, {price, []})
  end

  defp put_order({price, orders}, order), do: {price, [order | orders]}

  defp put_entry(entires, {price, _} = entry) do
    if List.keymember?(entires, price, 0) do
      List.keyreplace(entires, price, 0, entry)
    else
      [entry | entires]
    end
  end
end
