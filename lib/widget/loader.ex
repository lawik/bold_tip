defmodule BoldTip.Widget.Loader do
  use Agent

  alias BoldTip.Widget

  @default_widgets [
    Widget.Boolean,
    Widget.Composite,
    Widget.Datetime,
    Widget.File,
    Widget.Integer,
    Widget.List,
    Widget.RichText,
    Widget.String,
    Widget.Textarea
  ]

  def start_link(widget_modules \\ []) do
    Agent.start_link(fn ->
      @default_widgets ++ widget_modules
      |> Enum.uniq()
      |> Enum.reduce(%{}, &unpack_widget/2)
    end, name: __MODULE__)
  end

  def get_types do
    Agent.get(__MODULE__, & &1)
  end

  def add(widget) do
    Agent.update(__MODULE__, fn widgets ->
      Enum.uniq([widget | widgets])
    end)
  end

  defp unpack_widget(widget, types) do
    {base_type, name} = apply(widget, :type, [])
    types = Map.put_new(types, base_type, %{})
    sub_types = Map.put_new(types[base_type], name, widget)
    Map.put(types, base_type, sub_types)
  end
end
