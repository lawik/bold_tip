defmodule BoldTip.Widget.RichText do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field
  alias BoldTip.Widget

  @behaviour Widget
  def type, do: {"string","richtext"}

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="<%= classes(__MODULE__, field.path, fieldset) %>">
      <div
        id="<%= id(field.path, fieldset.options) %>-editor"
        data-target="<%= id(field.path, fieldset.options) %>"
        class="boldtip-richtext-editor"
      ><%= value %></div>
      <textarea
        id="<%= id(field.path, fieldset.options) %>"
        class="boldtip-richtext-editor-target"
        name="<%= name(field.path, fieldset.options) %>"
      ><%= value %></textarea>
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

  defp default_value(nil), do: ""
  defp default_value(value), do: value
end
