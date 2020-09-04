defmodule BoldTip.Control do
  defstruct module: nil

  alias BoldTip.Control

  def new(module), do: %Control{module: module}
end
