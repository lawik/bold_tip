defmodule BoldTip.Widget.Integer do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field
  alias BoldTip.Widget

  @behaviour Widget
  def type, do: {"integer","integer"}

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="<%= classes(__MODULE__, field.path, fieldset) %>">
      <input
        type="number"
        id="<%= id(field.path, fieldset.options) %>"
        name="<%= name(field.path, fieldset.options) %>"
        value="<%= value %>" />
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

  defp default_value(nil), do: 0
  defp default_value(value), do: value
end
