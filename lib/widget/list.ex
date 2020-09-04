defmodule BoldTip.Widget.List do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field
  alias BoldTip.Widget

  @empty_placeholder "<p>- empty -</p>"


  @behaviour Widget
  def type, do: {"array","list"}

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="<%= classes(__MODULE__, field.path, fieldset) %>">
      <input
      type="hidden"
      name="<%= name(field.path, fieldset.options) %>"
      value="empty-list" />
      <div class="boldtip-field-list-items" id="<%= id(field.path, fieldset.options) %>">
      <%= for item <- list_items do %>
        <%= item %>
      <% end %>
      <input type="submit" name="<%= action(field.path, "add-item", fieldset.options) %>" value="Add item" />
      </div>
    </div>
    """,
    [:fieldset, :field, :list_items]
  )

  def render(fieldset, field) do
    value =
      field
      |> Field.get_value(fieldset.values)
      |> default_value()

    list_items =
      if value == [] do
        [@empty_placeholder]
      else
        render_child_fields(fieldset, field, "boldtip-field-list-item")
      end

    template(fieldset, field, list_items)
  end

  defp default_value(nil), do: []
  defp default_value(value), do: value

  def actions(fieldset, field) do
    actions = Field.get_actions(field, fieldset.actions)
    field_values = Field.get_value(field, fieldset.values)

    {applied, field_values} =
      Enum.reduce(actions, {0, field_values}, fn action, {applied, values} ->
        case action do
          "add-item" ->
            # Add a new value, nil triggers default value
            {applied + 1, values ++ [nil]}

          _ ->
            {applied, values}
        end
      end)

    values = Field.set_value(field, fieldset.values, field_values)
    {applied, values}
  end
end
