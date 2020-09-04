defmodule BoldTip.Params do
  alias BoldTip.Widget
  alias BoldTip.Fields.Field

  def fieldpath_to_paramkey(path, prefix, separator) do
    prefix <> separator <> Enum.join(path, separator)
  end

  def paramkey_to_fieldpath(key, prefix, separator) do
    key
    |> String.replace_leading(prefix <> separator, "")
    |> String.split(separator)
    |> Enum.map(fn part ->
      case Integer.parse(part) do
        {integer, ""} -> integer
        _ -> part
      end
    end)
  end

  def params_to_values(params, schema, schema_additions, options) do
    params
    |> Enum.reduce(%{}, fn {key, param_value}, values ->
      # Check if it has param prefix and strip it
      case strip_param_prefix(key, options) do
        nil -> values
        key -> param_to_values(key, param_value, values, schema, schema_additions, options)
      end
    end)
    # Transform maps that represent arrays/lists into proper lists and such
    |> clean_structure()
  end

  defp strip_param_prefix(key, options) do
    %{
      values_prefix: values_prefix,
      separator: separator
    } = options
    start = values_prefix <> separator
    if String.starts_with?(key, start) do
      String.replace(key, start, "")
    else
      nil
    end
  end

  defp param_to_values(key, value, values, schema, schema_additions, options) do
    %{separator: separator} = options

    [field_name | rest] = String.split(key, separator)
    local_field_path = [field_name]
    field_schema = Field.get_schema(local_field_path, schema)
    field_additions = Field.get_schema_additions(local_field_path, schema_additions)
    widget_module = Widget.get_widget_module(field_schema, field_additions)

    value = if Widget.has_value_handler?(widget_module) do
      %{map_to: :custom, value: value}
    else
      case {rest, field_schema["type"]} do
        {[], nil} ->
          # Simple object property, no schema definition, let's assume string
          to_value("string", value)
        {[], type} ->
          # Simple object property with schema definition, get value according to schema type
          to_value(type, value)
        {_rest, nil} ->
          # Complex value without schema definition
          raise "Encountered a nested field without a schema definition or custom value handling, not supported."
        {rest, "array"} ->
          deep_value = recurse_param_to_value(rest, field_schema, field_additions, value)
          current_value = Map.get(values, field_name, %{})
          deep_merge(current_value, deep_value)
        {rest, "object"} ->
          deep_value = recurse_param_to_value(rest, field_schema, field_additions, value)
          current_value = Map.get(values, field_name, %{})
          deep_merge(current_value, deep_value)
      end
    end

    Map.put(values, field_name, value)
  end

  defp recurse_param_to_value([next | rest], %{"type" => "array"} = field_schema, field_additions, value) do
    index = String.to_integer(next)
    sub_schema = Map.get(field_schema, "items", nil)
    sub_additions = case field_additions do
      nil -> nil
      field_additions -> Map.get(field_additions, "$items", nil)
    end

    value = recurse_param_to_value(rest, sub_schema, sub_additions, value)
    %{
      :map_to => :list,
      index => value
    }
  end

  defp recurse_param_to_value([next | rest], %{"type" => "object"} = field_schema, field_additions, value) do
    property = next
    sub_schema = case Map.get(field_schema, "properties", nil) do
      nil -> nil
      schema_properties -> Map.get(schema_properties, property, nil)
    end
    sub_additions = case field_additions do
      nil -> nil
      field_additions -> case Map.get(field_additions, "$properties", nil) do
        nil -> nil
        addition_properties -> Map.get(addition_properties, property, nil)
      end
    end

    value = recurse_param_to_value(rest, sub_schema, sub_additions, value)
    %{
      :map_to => :map,
      property => value
    }
  end

  defp recurse_param_to_value(rest, field_schema, field_additions, value) do
    widget_module = Widget.get_widget_module(field_schema, field_additions)
    if Widget.has_value_handler?(widget_module) do
      %{map_to: :custom, value: value}
    else
      case {rest, field_schema["type"]} do
        {[], nil} ->
          # Leaf value, no schema definition, let's assume string
          to_value("string", value)
        {[], type} ->
          # Leaf value, with schema definition, no custom value handling from widget, format value by schema type
          to_value(type, value)
        {_rest, nil} ->
          # Nested field without custom value handling or schema definition, not supported
          raise "Encountered a nested field without a schema definition or custom value handling, not supported."
        {rest, _type} ->
          # Complex nested field
          recurse_param_to_value(rest, field_schema, field_additions, value)
      end
    end
  end

  def params_to_actions(params, options) do
    %{
      actions_prefix: actions_prefix,
      separator: separator,
      section_separator: section_separator
    } = options

    start = actions_prefix <> separator

    params
    |> Enum.filter(fn {key, _value} ->
      String.starts_with?(key, start)
    end)
    |> Enum.map(fn {key, _value} ->
      action_string = String.replace_leading(key, start, "")
      [paramkey, action_name] = String.split(action_string, section_separator)
      field_path = paramkey
      |> String.split(separator)
      |> Enum.map(fn part ->
        case Integer.parse(part) do
          {num, ""} -> num
          _ -> part
        end
      end)
      {field_path, action_name}
    end)
    # Simplify to map
    |> Enum.reduce(%{}, fn {fieldpath, action_name}, actions ->
      action_list = Map.get(actions, fieldpath, [])
      Map.put(actions, fieldpath, [action_name | action_list])
    end)
    # Sort the actions
    |> Enum.reduce(%{}, fn {key, value}, result ->
      Map.put(result, key, Enum.sort(value))
    end)
  end

  def get_field_actions(actions, fieldpath) do
    Map.get(actions, fieldpath, [])
  end

  defp to_value("boolean", value) do
    case value do
      "1" -> true
      "true" -> true
      "yes" -> true
      1 -> true
      true -> true
      _ -> false
    end
  end

  defp to_value("integer", value) do
    String.to_integer(value)
  end

  defp to_value("number", value) do
    String.to_float(value)
  end

  defp to_value("string", value) do
    value
  end

  defp to_value("array", _) do
    %{:map_to => :list}
  end

  defp to_value(type, _value) do
    raise "value type #{type} not implemented"
  end

  defp clean_structure(values) do
    if is_map(values) do
      # Get and remove the map_to annotation if it exists
      {map_to, values} = Map.pop(values, :map_to, nil)

      case map_to do
        nil ->
          values
          |> Enum.reduce(values, fn {field, value}, values ->
            if is_map(value) do
              Map.put(values, field, clean_structure(value))
            else
              values
            end
          end)

        :list ->
          values
          |> Enum.sort()
          |> Enum.map(fn {_index, value} ->
            clean_structure(value)
          end)

        :map ->
          clean_structure(values)

        :custom ->
          values.value
      end
    else
      values
    end
  end

  defp deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end
end
