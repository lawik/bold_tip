defmodule BoldTip.Control.Label do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="boldtip-control boldtip-control-label">
      <label class="boldtip-label" for="<%= id(field.path, fieldset.options) %>"><%= title(fieldset, field) %></label>
    </div>
    """,
    [:fieldset, :field]
  )

  def render(fieldset, field) do
    template(fieldset, field)
  end

  def title(fieldset, field) do
    extra = Field.get_schema_additions(field, fieldset.schema_additions)
    extra["title"] || prettify(field.name)
  end

  def prettify(field_name) do
    leading_character = String.first(field_name)
    upper = String.upcase(leading_character)
    field_name = String.replace_prefix(field_name, leading_character, upper)

    Regex.split(~r/([A-Z][a-z]+)/, field_name, include_captures: true)
    |> String.split("_")
    |> Enum.join(" ")
    # Noice!
    |> String.replace("UR Ls", "URLs")
    |> String.replace(~r/ +/, " ")
    |> String.trim()
  end
end
