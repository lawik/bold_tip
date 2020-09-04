defmodule BoldTip.ActionsTest do
  use ExUnit.Case

  @schema %{
    "type" => "object",
    "properties" => %{
      "listOfThings" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "properties" => %{
            "name" => %{
              "type" => "string"
            },
            "description" => %{
              "type" => "string"
            }
          },
          "required" => ["name"]
        }
      }
    },
    "required" => []
  }

  defp param(params, param, value) do
    Map.put(params, param, value)
  end

  defp action(params, action) do
    Map.put(params, action, "-")
  end

  test "add field, add item, add field in item" do
    fieldset = BoldTip.fieldset_from_values(%{}, @schema)
    html = BoldTip.render_fields(fieldset)
    assert html =~ "action-----add-field-listOfThings"

    # Send the add field action via params
    params = action(%{}, "action-----add-field-listOfThings")

    fieldset = params
    |> BoldTip.fieldset_from_params(@schema)
    |> BoldTip.apply_actions()

    html = BoldTip.render_fields(fieldset)
    assert html =~ "id--listOfThings"
    assert html =~ "action--listOfThings---add-item"

    # Send the add item action via params along with current values
    params = %{}
    |> param("value--listOfThings", "empty-list")
    |> action("action--listOfThings---add-item")

    fieldset = params
    |> BoldTip.fieldset_from_params(@schema)
    |> BoldTip.apply_actions()
    html = BoldTip.render_fields(fieldset)

    assert html =~ "value--listOfThings--0--name"
    assert html =~ "action--listOfThings--0---add-field-description"

    # Add the description field to an item
    params = %{}
    |> param("value--listOfThings--0--name", "fnork")
    |> action("action--listOfThings--0---add-field-description")

    fieldset = params
    |> BoldTip.fieldset_from_params(@schema)
    |> BoldTip.apply_actions()
    html = BoldTip.render_fields(fieldset)

    assert html =~ "value--listOfThings--0--description"

    # Remove description field
    params = %{}
    |> param("value--listOfThings--0--name", "fnork")
    |> param("value--listOfThings--0--description", "fnork")
    |> action("action--listOfThings--0--description---remove-field")

    fieldset = params
    |> BoldTip.fieldset_from_params(@schema)
    |> BoldTip.apply_actions()
    html = BoldTip.render_fields(fieldset)

    refute html =~ "value--listOfThings--0--description"

    # Remove the entire list
    params = %{}
    |> param("value--listOfThings--0--name", "fnork")
    |> action("action--listOfThings---remove-field")

    fieldset = params
    |> BoldTip.fieldset_from_params(@schema)
    |> BoldTip.apply_actions()
    html = BoldTip.render_fields(fieldset)

    refute html =~ "id--listOfThings"
  end

end
