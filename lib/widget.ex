defmodule BoldTip.Widget do
  alias BoldTip.Fields.Field
  alias BoldTip.Fieldset
  alias BoldTip.Widget.Loader

  @default_type "string"
  @default_format "default"

  @list_type "array"
  @list_format "list"

  @map_type "object"
  @map_format "composite"

  @callback type() :: {String.t(), String.t()}
  @callback render(%Fieldset{}, %Field{}) :: String.t()

  # Can be replaced with a GenServer where Widgets can be registered later on
  def get_widget_module(%Fieldset{} = fieldset, %Field{} = field) do
    schema = Field.get_schema(field, fieldset.schema)
    schema_additions = Field.get_schema_additions(field, fieldset.schema_additions)
    value = Field.get_value(field, fieldset.values)

    get_widget_module(schema, schema_additions, value)
  end

  def get_widget_module(schema, schema_additions, value \\ nil) do
    {type, widget} =
      case schema do
        nil ->
          case value do
            value when is_list(value) -> {@list_type, @list_format}
            value when is_map(value) -> {@map_type, @map_format}
            _ -> {@default_type, @default_format}
          end

        schema ->
          type = determine_type(schema)
          widget = determine_widget(schema, schema_additions)
          {type, widget}
      end

    widget_modules = get_widget_modules()
    if widget == "default" do
      # Attempt to get a type-named widget
      case get_in(widget_modules, [type, type]) do
        nil ->
          # Fall back to picking the first one
          case Map.get(widget_modules, type, nil) do
            nil -> nil
            type_widgets ->
              type_widgets
              |> Enum.find(fn _ -> true end)
              |> elem(1)
          end
        module -> module
      end
    else
      get_in(widget_modules, [type, widget])
    end
  end

  def has_value_handler?(module) do
    function_exported?(module, :handle_value, 2)
  end

  def handle_value(module, fieldset, field) do
    apply(module, :handle_value, [fieldset, field])
  end

  def has_actions?(module) do
    function_exported?(module, :actions, 2)
  end

  def handle_actions(module, fieldset, field) do
    apply(module, :actions, [fieldset, field])
  end

  defp determine_type(schema), do: Map.get(schema, "type", @default_type)

  defp determine_widget(schema, nil) do
    Map.get(schema, "format", @default_format)
  end

  defp determine_widget(schema, schema_additions) do
    Map.get(schema_additions, "widget", determine_widget(schema, nil))
  end

  defp get_widget_modules() do
    Loader.get_types()
  end
end
