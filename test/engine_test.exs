defmodule Exchange.EngineTest do
  use ExUnit.Case

  alias Exchange.Engine

  test "add a single buy order to the order book" do
    {:ok, engine} = Engine.start_link(:test)
    order = %{side: :buy, size: 100, price: 50_00}

    Engine.add(engine, order)

    {buy, _sell} = Engine.book(engine)
    assert buy == [{50_00, [order]}]
  end

  test "add two buy orders, with higher order first" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{side: :buy, size: 100, price: 51_00}
    order_2 = %{side: :buy, size: 100, price: 50_00}

    Engine.add(engine, order_1)
    Engine.add(engine, order_2)

    {buy, _sell} = Engine.book(engine)
    assert buy == [{51_00, [order_1]}, {50_00, [order_2]}]
  end

  test "add two buy orders, with lower order first" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{side: :buy, size: 100, price: 51_00}
    order_2 = %{side: :buy, size: 100, price: 50_00}

    Engine.add(engine, order_2)
    Engine.add(engine, order_1)

    {buy, _sell} = Engine.book(engine)
    assert buy == [{51_00, [order_1]}, {50_00, [order_2]}]
  end

  test "add two buy orders with the same price" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{side: :buy, size: 100, price: 50_00}
    order_2 = %{side: :buy, size: 100, price: 50_00}

    Engine.add(engine, order_1)
    Engine.add(engine, order_2)

    {buy, _sell} = Engine.book(engine)
    assert buy == [{50_00, [order_1, order_2]}]
  end

  test "add a single sell limit order to order book" do
    {:ok, engine} = Engine.start_link(:test)
    order = %{side: :sell, size: 100, price: 50_00}

    Engine.add(engine, order)

    {_buy, sell} = Engine.book(engine)
    assert sell == [{50_00, [order]}]
  end

  test "add two sell orders, with higher order first" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{side: :sell, size: 100, price: 51_00}
    order_2 = %{side: :sell, size: 100, price: 50_00}

    Engine.add(engine, order_1)
    Engine.add(engine, order_2)

    {_buy, sell} = Engine.book(engine)
    assert sell == [{50_00, [order_2]}, {51_00, [order_1]}]
  end

  test "add two sell orders, with lower order first" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{side: :sell, size: 100, price: 51_00}
    order_2 = %{side: :sell, size: 100, price: 50_00}

    Engine.add(engine, order_2)
    Engine.add(engine, order_1)

    {_buy, sell} = Engine.book(engine)
    assert sell == [{50_00, [order_2]}, {51_00, [order_1]}]
  end

  test "add two sell orders with the same price" do
    {:ok, engine} = Engine.start_link(:test)
    order_1 = %{side: :sell, size: 100, price: 50_00}
    order_2 = %{side: :sell, size: 100, price: 50_00}

    Engine.add(engine, order_1)
    Engine.add(engine, order_2)

    {_buy, sell} = Engine.book(engine)
    assert sell == [{50_00, [order_1, order_2]}]
  end
end
