defmodule BoldTip.Fields.Field do
  defstruct name: nil,
            widget_module: nil,
            path: nil,
            fields: [],
            controls: %{
              before: [],
              after: []
            }

  alias BoldTip.Fields.Field

  def new(name, path, module, fields \\ []) do
    %Field{
      name: name,
      widget_module: module,
      path: path,
      fields: fields
    }
  end

  def get_parent_path(path) when is_list(path) do
    path
    |> Enum.reverse()
    |> tl()
    |> Enum.reverse()
  end

  def get_parent_path(field), do: get_parent_path(field.path)

  def get_schema_additions([], schema_additions), do: schema_additions

  def get_schema_additions(path, schema_additions) when is_list(path) do
    path_to_schema_additions(path, schema_additions)
  end

  def get_schema_additions(field, schema_additions),
    do: get_schema_additions(field.path, schema_additions)

  def get_actions([], actions), do: Map.get(actions, [""], nil)

  def get_actions(path, actions) when is_list(path) do
    case Map.get(actions, path, nil) do
      nil -> []
      actions -> actions
    end
  end

  def get_actions(field, actions), do: get_actions(field.path, actions)

  def get_value([], values), do: values
  def get_value(path, values) when is_list(path), do: get_in(values, access_path(path))
  def get_value(field, values), do: get_value(field.path, values)

  def set_value([], _values, value), do: value

  def set_value(path, values, value) when is_list(path),
    do: put_in(values, access_path(path), value)

  def set_value(field, values, value), do: set_value(field.path, values, value)

  def get_schema([], schema), do: schema
  def get_schema(path, schema) when is_list(path), do: path_to_schema(path, schema)
  def get_schema(field, schema), do: get_schema(field.path, schema)

  def get_errors([], errors), do: errors

  def get_errors(path, errors) when is_list(path) do
    case errors do
      %{reason: errors} ->
        path_to_errors(path, errors)

      _ ->
        nil
    end
  end

  def get_errors(field, errors), do: get_errors(field.path, errors)

  defp access_path(path) do
    Enum.map(path, fn k ->
      case k do
        k when is_integer(k) -> at(k)
        k -> k
      end
    end)
  end

  # Custom implementation of Access.at to avoid error on incomplete structure
  defp at(index) when is_integer(index) do
    fn op, data, next -> at(op, data, index, next) end
  end

  defp at(:get, data, index, next) when is_list(data) do
    data |> Enum.at(index) |> next.()
  end

  defp at(:get_and_update, data, index, next) when is_list(data) do
    get_and_update_at(data, index, next, [])
  end

  # Not a list, always nil
  defp at(_op, _data, _index, next) do
    next.(nil)
  end

  defp get_and_update_at([head | rest], 0, next, updates) do
    case next.(head) do
      {get, update} -> {get, :lists.reverse([update | updates], rest)}
      :pop -> {head, :lists.reverse(updates, rest)}
    end
  end

  defp get_and_update_at(list, index, next, updates) when index < 0 do
    list_length = length(list)

    if list_length + index >= 0 do
      get_and_update_at(list, list_length + index, next, updates)
    else
      {nil, list}
    end
  end

  defp get_and_update_at([head | rest], index, next, updates) when index > 0 do
    get_and_update_at(rest, index - 1, next, [head | updates])
  end

  defp get_and_update_at([], _index, _next, updates) do
    {nil, :lists.reverse(updates)}
  end

  defp path_to_schema([], current_schema), do: current_schema

  defp path_to_schema(path, %{"type" => "object", "properties" => current_schema}) do
    # Object type, drill past schema structure
    path_to_schema(path, current_schema)
  end

  defp path_to_schema([_next | rest], %{"type" => "array", "items" => current_schema}) do
    # Array type, drill past schema structure and past index key
    path_to_schema(rest, current_schema)
  end

  defp path_to_schema([next | rest], current_schema) do
    if Map.has_key?(current_schema, next) do
      path_to_schema(rest, current_schema[next])
    else
      nil
    end
  end

  defp path_to_schema_additions([], current_schema), do: current_schema

  defp path_to_schema_additions(path, %{"$properties" => current_schema}) do
    # Object type, drill past schema structure
    path_to_schema_additions(path, current_schema)
  end

  defp path_to_schema_additions([_next | rest], %{"$items" => current_schema}) do
    # Array type, drill past schema structure and past index key
    path_to_schema_additions(rest, current_schema)
  end

  defp path_to_schema_additions([next | rest], current_schema) do
    if Map.has_key?(current_schema, next) do
      path_to_schema_additions(rest, current_schema[next])
    else
      nil
    end
  end

  defp path_to_errors([], current_errors), do: current_errors

  defp path_to_errors(path, %{properties: current_errors}) do
    path_to_errors(path, current_errors)
  end

  defp path_to_errors(path, %{items: current_errors}) do
    path_to_errors(path, current_errors)
  end

  defp path_to_errors([next | rest], current_errors) when is_integer(next) do
    case Enum.find(current_errors, nil, fn {index, _} ->
           index == next
         end) do
      nil -> nil
      {_, current_errors} -> path_to_errors(rest, current_errors)
    end
  end

  defp path_to_errors([next | rest], current_errors) when is_binary(next) do
    if Map.has_key?(current_errors, next) do
      path_to_errors(rest, current_errors[next])
    else
      nil
    end
  end
end
