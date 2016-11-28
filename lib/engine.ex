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

  def handle_cast({:add, order}, books) do
    {:noreply, handle_add_order(books, order)}
  end

  def handle_call(:book, _, books) do
    {:reply, books, books}
  end

  ## Private ###################################################################

  defp handle_add_order({buy_side, sell_side}, %{side: :buy} = order) do
    {sell_side, order} = match_order(sell_side, order)
    buy_side = add_order(buy_side, order)
    {buy_side, sell_side}
  end

  defp handle_add_order({buy_side, sell_side}, %{side: :sell} = order) do
    {buy_side, order} = match_order(buy_side, order)
    sell_side = add_order(sell_side, order)
    {buy_side, sell_side}
  end

  def match_order(entries, order) do
    case top(entries) do
      nil ->
        {entries, order}

      {price, _orders} ->
        if matching?(price, order) do
          {rest(entries), Map.put(order, :size, 0)}
        else
          {entries, order}
        end
    end
  end

  def add_order(entries, %{size: 0}), do: entries
  def add_order(entries, %{size: size} = order) when size > 0 do
    entry =
      entries
      |> find_entry(order)
      |> put_order(order)

    entries = entries |> put_entry(entry)

    case order do
      %{side: :buy}   -> Enum.sort(entries, &buy_book_sort/2)
      %{side: :sell}  -> Enum.sort(entries, &sell_book_sort/2)
    end
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

  defp top([entry | _]), do: entry
  defp top([]),          do: nil

  defp rest([_ | r]),    do: r
  defp rest([]),         do: []


  defp sell_book_sort({p1, _}, {p2, _}), do: p1 < p2

  defp buy_book_sort({p1, _}, {p2, _}), do: p1 > p2

  defp matching?(price, %{side: :buy, price: order_price}) do
    price <= order_price
  end

  defp matching?(price, %{side: :sell, price: order_price}) do
    price >= order_price
  end
end
