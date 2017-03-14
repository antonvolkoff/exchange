defmodule Exchange do
  @moduledoc """
  Documentation for Exchange.
  """

  @doc """
  Adds an order to the order book.
  """
  def add(order) do
    Exchange.Engine.add(Exchange.Engine, order)
  end

  @doc """
  Returns current order book depth.
  """
  def book do
    Exchange.Engine.book(Exchange.Engine)
  end
end
