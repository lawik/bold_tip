defmodule BoldTip.Widget.Boolean do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field
  alias BoldTip.Widget

  @behaviour Widget
  def type, do: {"boolean","boolean"}

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="<%= classes(__MODULE__, field.path, fieldset) %>">
      <input
        type="hidden"
        name="<%= name(field.path, fieldset.options) %>"
        value="false" />
      <%= if value do %>
        <input
          type="checkbox"
          id="<%= id(field.path, fieldset.options) %>"
          name="<%= name(field.path, fieldset.options) %>"
          value="true"
          checked="checked" />
      <% else %>
        <input
          type="checkbox"
          id="<%= id(field.path, fieldset.options) %>"
          name="<%= name(field.path, fieldset.options) %>"
          value="true" />
      <% end %>
    </div>
    """,
    [:fieldset, :field, :value]
  )

  def render(fieldset, field) do
    value =
      field
      |> Field.get_value(fieldset.values)
      |> default_value()

    template(fieldset, field, value)
  end

  defp default_value(nil), do: false
  defp default_value(value) when not is_boolean(value), do: false
  defp default_value(value), do: value
end
