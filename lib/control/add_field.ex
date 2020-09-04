defmodule BoldTip.Control.AddField do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field
  alias BoldTip.Control.Label

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="boldtip-control boldtip-control-addfield">
      <label for="<%= id(field.path, fieldset.options, "toggle") %>" class="meta-add-field-label">Add field</label>
      <input id="<%= id(field.path, fieldset.options, "toggle") %>" class="meta-add-field" type="checkbox" name="id(field.path, fieldset.options, "toggle-ignore")" value="1" />
      <div class="add-field-selector">
      <%= if field_schema["properties"] do %>
        <%= for {key, schema} <- field_schema["properties"] do %>
          <%= if is_nil(field_values) or key not in Map.keys(field_values) do %>
          <div class="add-field">
            <p>
              <strong><%= Label.prettify(key) %></strong>
              <br />
              <%= schema["description"] %>
            </p>
            <input class="button-outline" name="<%= action(field.path, "add-field-" <> key, fieldset.options) %>" type="submit" value="Add" />
          </div>
          <% end %>
        <% end %>
      <% end %>
      </div>
    </div>
    """,
    [:fieldset, :field, :field_values, :field_schema]
  )

  def render(fieldset, field) do
    field_schema = Field.get_schema(field, fieldset.schema)

    case field_schema do
      %{"type" => "object", "properties" => props} ->
        field_values = Field.get_value(field, fieldset.values)

        if not is_nil(field_values) and Enum.all?(props, fn {key, _} -> Map.has_key?(field_values, key) end) do
          ""
        else
          template(fieldset, field, field_values, field_schema)
        end

      _ ->
        ""
    end
  end

  def actions(fieldset, field) do
    actions = Field.get_actions(field, fieldset.actions)
    field_values = Field.get_value(field, fieldset.values)
    schema = Field.get_schema(field, fieldset.schema)

    {applied, field_values} =
      Enum.reduce(actions, {0, field_values}, fn action, {applied, field_values} ->
        case action do
          "add-field-" <> field_name ->
            if Map.has_key?(schema, "properties") and
                 Map.has_key?(schema["properties"], field_name) do
              # Add a nil value to the item
              {applied + 1, Map.put(field_values, field_name, nil)}
            else
              {applied, field_values}
            end

          _ ->
            {applied, field_values}
        end
      end)

    values = Field.set_value(field, fieldset.values, field_values)
    {applied, values}
  end

end
