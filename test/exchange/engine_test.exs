defmodule Exchange.EngineTest do
  use ExUnit.Case

  alias Exchange.Engine

  test "add a single buy order to the order book" do
    {:ok, engine} = Engine.start_link(:test)
    order = %{id: "a", side: :buy, size: 100, price: 50_00}

    Engine.add(engine, order)

    {buy, _sell} = Engine.book(engine)
    assert buy == [{50_00, 100, [order]}]
  end

  test "add two buy orders, with higher order first" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{id: "a", side: :buy, size: 100, price: 51_00}
    order_2 = %{id: "b", side: :buy, size: 100, price: 50_00}

    Engine.add(engine, order_1)
    Engine.add(engine, order_2)

    {buy, _sell} = Engine.book(engine)
    assert buy == [{51_00, 100, [order_1]}, {50_00, 100, [order_2]}]
  end

  test "add two buy orders, with lower order first" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{id: "a", side: :buy, size: 100, price: 51_00}
    order_2 = %{id: "b", side: :buy, size: 100, price: 50_00}

    Engine.add(engine, order_2)
    Engine.add(engine, order_1)

    {buy, _sell} = Engine.book(engine)
    assert buy == [{51_00, 100, [order_1]}, {50_00, 100, [order_2]}]
  end

  test "add two buy orders with the same price" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{id: "a", side: :buy, size: 100, price: 50_00}
    order_2 = %{id: "b", side: :buy, size: 100, price: 50_00}

    Engine.add(engine, order_1)
    Engine.add(engine, order_2)

    {buy, _sell} = Engine.book(engine)
    assert buy == [{50_00, 200, [order_1, order_2]}]
  end

  test "add a single sell limit order to order book" do
    {:ok, engine} = Engine.start_link(:test)
    order = %{id: "a", side: :sell, size: 100, price: 50_00}

    Engine.add(engine, order)

    {_buy, sell} = Engine.book(engine)
    assert sell == [{50_00, 100, [order]}]
  end

  test "add two sell orders, with higher order first" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{id: "a", side: :sell, size: 100, price: 51_00}
    order_2 = %{id: "b", side: :sell, size: 100, price: 50_00}

    Engine.add(engine, order_1)
    Engine.add(engine, order_2)

    {_buy, sell} = Engine.book(engine)
    assert sell == [{50_00, 100, [order_2]}, {51_00, 100, [order_1]}]
  end

  test "add two sell orders, with lower order first" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{id: "a", side: :sell, size: 100, price: 51_00}
    order_2 = %{id: "b", side: :sell, size: 100, price: 50_00}

    Engine.add(engine, order_2)
    Engine.add(engine, order_1)

    {_buy, sell} = Engine.book(engine)
    assert sell == [{50_00, 100, [order_2]}, {51_00, 100, [order_1]}]
  end

  test "add two sell orders with the same price" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{id: "a", side: :sell, size: 100, price: 50_00}
    order_2 = %{id: "b", side: :sell, size: 100, price: 50_00}

    Engine.add(engine, order_1)
    Engine.add(engine, order_2)

    {_buy, sell} = Engine.book(engine)
    assert sell == [{50_00, 200, [order_1, order_2]}]
  end

  test "matching a single buy order against identical outstanding sell order" do
    # Example(1): exact same price as top of the Sell order book
    {:ok, engine} = Engine.start_link(:test)
    init_orders!(engine)

    Engine.add(engine, %{side: :buy, size: 100, price: 57_00})

    {buy, sell} = Engine.book(engine)
    assert [{54_00, 100, _}, {53_00, 200, _}] = buy
    assert [{58_00, 200, _}] = sell

    # Example(2): higher price then the top of the Sell book
    {:ok, engine} = Engine.start_link(:test2)
    init_orders!(engine)

    Engine.add(engine, %{side: :buy, size: 100, price: 58_00})

    {buy, sell} = Engine.book(engine)
    assert [{54_00, 100, _}, {53_00, 200, _}] = buy
    assert [{58_00, 200, _}] = sell
  end

  test "matching a single sell order against identical outstanding buy order" do
    # Example(1): exact same price as top of the buy order book
    {:ok, engine} = Engine.start_link(:test)
    init_orders!(engine)

    Engine.add(engine, %{side: :sell, size: 100, price: 54_00})

    {buy, sell} = Engine.book(engine)
    assert [{53_00, 200, _}] = buy
    assert [{57_00, 100, _}, {58_00, 200, _}] = sell

    # Example(2): higher price then the top of the buy book
    {:ok, engine} = Engine.start_link(:test2)
    init_orders!(engine)

    Engine.add(engine, %{side: :sell, size: 100, price: 53_00})

    {buy, sell} = Engine.book(engine)
    assert [{53_00, 200, _}] = buy
    assert [{57_00, 100, _}, {58_00, 200, _}] = sell
  end

  test "matching a buy order large enough to clear the sell book" do
    {:ok, engine} = Engine.start_link(:test)
    init_orders!(engine)

    Engine.add(engine, %{side: :buy, size: 350, price: 58_00})

    {buy, sell} = Engine.book(engine)
    assert [{58_00, 50, [%{size: 50}]}, {54_00, 100, _}, {53_00, 200, _}] = buy
    assert [] = sell
  end

  test "matching a sell order large enough to clear the buy book" do
    {:ok, engine} = Engine.start_link(:test)
    init_orders!(engine)

    Engine.add(engine, %{side: :sell, size: 350, price: 53_00})

    {buy, sell} = Engine.book(engine)
    assert [] = buy
    assert [{53_00, 50, _}, {57_00, 100, _}, {58_00, 200, _}] = sell
  end

  test "matching a large buy order partially" do
    {:ok, engine} = Engine.start_link(:test)
    init_orders!(engine)

    Engine.add(engine, %{side: :buy, size: 350, price: 57_00})

    {buy, sell} = Engine.book(engine)
    assert [{57_00, 250, _}, {54_00, 100, _}, {53_00, 200, _}] = buy
    assert [{58_00, 200, _}] = sell
  end

  test "matching a large sell order partially" do
    {:ok, engine} = Engine.start_link(:test)
    init_orders!(engine)

    Engine.add(engine, %{side: :sell, size: 350, price: 54_00})

    {buy, sell} = Engine.book(engine)
    assert [{53_00, 200, _}] = buy
    assert [{54_00, 250, _}, {57_00, 100, _}, {58_00, 200, _}] = sell
  end

  test "matching a small buy order" do
    {:ok, engine} = Engine.start_link(:test)
    init_orders!(engine)

    Engine.add(engine, %{side: :buy, size: 50, price: 57_00})

    {buy, sell} = Engine.book(engine)
    assert [{54_00, 100, _}, {53_00, 200, _}] = buy
    assert [{57_00, 50, [%{size: 50}]}, {58_00, 200, _}] = sell
  end

  test "matching a small sell order" do
    {:ok, engine} = Engine.start_link(:test)
    init_orders!(engine)

    Engine.add(engine, %{side: :sell, size: 50, price: 54_00})

    {buy, sell} = Engine.book(engine)
    assert [{54_00, 50, [%{size: 50}]}, {53_00, 200, _}] = buy
    assert [{57_00, 100, _}, {58_00, 200, _}] = sell
  end

  def init_orders!(engine) do
    Engine.add(engine, %{side: :buy, size: 100, price: 54_00})
    Engine.add(engine, %{side: :buy, size: 200, price: 53_00})
    Engine.add(engine, %{side: :sell, size: 100, price: 57_00})
    Engine.add(engine, %{side: :sell, size: 200, price: 58_00})

    assert {buy_book, sell_book} = Engine.book(engine)
    assert [{54_00, 100, _}, {53_00, 200, _}] = buy_book
    assert [{57_00, 100, _}, {58_00, 200, _}] = sell_book
  end
end
