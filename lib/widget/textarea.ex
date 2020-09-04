defmodule BoldTip.Widget.Textarea do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field
  alias BoldTip.Widget

  @behaviour Widget
  def type, do: {"string","multiline"}

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="<%= classes(__MODULE__, field.path, fieldset) %>">
      <textarea
        id="<%= id(field.path, fieldset.options) %>"
        name="<%= name(field.path, fieldset.options) %>"><%= value %></textarea>
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
