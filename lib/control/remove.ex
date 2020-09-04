defmodule BoldTip.Control.Remove do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="boldtip-control boldtip-control-remove">
      <input type="submit" class="remove" name="<%= action(field.path, "remove-field", fieldset.options) %>" value="Remove" />
    </div>
    """,
    [:fieldset, :field]
  )

  def render(fieldset, field) do
    template(fieldset, field)
  end

  def actions(fieldset, field) do
    actions = Field.get_actions(field, fieldset.actions)
    parent_path = Field.get_parent_path(field.path)
    parent_values = Field.get_value(parent_path, fieldset.values)

    {applied, parent_values} =
      Enum.reduce(actions, {0, parent_values}, fn action, {applied, values} ->
        case action do
          "remove-field" ->
            # Add a new value, nil triggers default value
            values =
              case values do
                values when is_list(values) ->
                  values
                  |> Enum.with_index()
                  |> Enum.reject(fn {_item, index} ->
                    index == field.name
                  end)
                  |> Enum.map(fn {item, _index} ->
                    item
                  end)

                values when is_map(values) ->
                  Map.delete(values, field.name)
              end

            {applied + 1, values}

          _ ->
            {applied, values}
        end
      end)

    values = Field.set_value(parent_path, fieldset.values, parent_values)
    {applied, values}
  end
end
