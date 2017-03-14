# Exchange



## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `exchange` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:exchange, "~> 0.1.0"}]
    end
    ```

  2. Ensure `exchange` is started before your application:

    ```elixir
    def application do
      [applications: [:exchange]]
    end
    ```

## How it works?

Let's imagine there are few buy orders placed on a market:

  ```elixir
  alias Exchange.Engine

  {:ok, engine} = Engine.start_link(:test)

  Engine.add(engine, %{id: "1", side: :buy, size: 20, price: 10_20})
  Engine.add(engine, %{id: "2", side: :buy, size: 100, price: 10_20})
  Engine.add(engine, %{id: "3", side: :buy, size: 80, price: 10_20})
  Engine.add(engine, %{id: "4", side: :sell, size: 30, price: 10_22})
  ```

Which makes order book look like this:

| ID | Side | Qty    | Price | Qty    | Side |
|----|------|--------|-------|--------|------|
|    |      |        | 10.23 |        |      |
| 4  |      |        | 10.22 | 30     | SELL |
|    |      |        | 10.21 |        |      |
| 1  | BUY  | 20     | 10.20 |        |      |
| 2  | BUY  | 100    | 10.20 |        |      |
| 3  | BUY  | 80     | 10.20 |        |      |
|    |      |        | 10.19 |        |      |

Now let's place a sell order for 150@10.20

  ```elixir
  Engine.add(engine, %{id: "5", side: :sell, size: 120, price: 10_20})
  ```

Now our order book looks like this:

| ID | Side | Qty    | Price | Qty    | Side |
|----|------|--------|-------|--------|------|
| 4  |      |        | 10.22 | 30     | SELL |
|    |      |        | 10.21 |        |      |
| 3  | BUY  | 80(50) | 10.20 |        |      |
|    |      |        | 10.19 |        |      |

Order #1 and #2 were fully filled and order #3 were partially
filled by new sell order.
