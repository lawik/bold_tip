defmodule BoldTip.Widget.Select do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field
  alias BoldTip.Widget

  @behaviour Widget
  def type, do: {"string", "select"}
  def special_case(%{"enum" => enum}, _) when is_list(enum), do: true
  def special_case(_, _), do: false

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="<%= classes(__MODULE__, field.path, fieldset) %>">
      <select
        type="text"
        id="<%= id(field.path, fieldset.options) %>"
        name="<%= name(field.path, fieldset.options) %>">
        <%= for option <- options do %>
          <option value="<%= option %>" <%= selected(option, value) %>><%= option %></option>
        <% end %>
      </select>
    </div>
    """,
    [:fieldset, :field, :options, :value]
  )

  def render(fieldset, field) do
    %{"enum" => options} = Field.get_schema(field, fieldset.schema)

    value =
      field
      |> Field.get_value(fieldset.values)
      |> default_value()

    template(fieldset, field, options, value)
  end

  defp default_value(nil), do: ""
  defp default_value(value), do: value
  defp selected(option, value) when option == value, do: "selected"
  defp selected(_, _), do: ""
end
