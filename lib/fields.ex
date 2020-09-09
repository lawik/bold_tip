defmodule BoldTip.Fields do

  alias BoldTip.Control
  alias BoldTip.Fields.Field
  alias BoldTip.Widget
  alias BoldTip.Widget.Base

  require Logger
  require EEx

  def build_fields(fieldset, opts) do
    [build(fieldset, "", [], opts)]
  end

  def build_fields(fieldset, root_field, opts) do
    current_schema = Field.get_schema(root_field, fieldset.schema)
    schema_additions = Field.get_schema_additions(root_field, fieldset.schema_additions) || %{}
    widget_module = Widget.get_widget_module(fieldset, root_field)
    current_values = Field.get_value(root_field, fieldset.values)
    current_values = if Keyword.get(opts, :nil_required, true) do
      add_required_values(current_values, current_schema)
    else
      current_values
    end

    cond do
      # Assume no underlying fields, must be checked, can be a non-structural map
      Widget.has_value_handler?(widget_module) -> []
      is_list(current_values) or is_map(current_values) ->
        current_values
        |> Enum.reject(fn item ->
          case item do
            {key, _} -> String.starts_with?(key, "meta-")
            _ -> false
          end
        end)
        |> sort_values(schema_additions)
        |> build_fields_by_type(current_schema, fieldset, root_field, opts)
        |> Enum.reverse()
      true -> []
    end
  end

  defp build_fields_by_type(
         current_values,
         %{"type" => "object", "properties" => _},
         fieldset,
         field,
         opts
       ) do
    build_fields_for_object(current_values, fieldset, field, opts)
  end

  defp build_fields_by_type(current_values, %{"type" => "array", "items" => _}, fieldset, field, opts) do
    build_fields_for_list(current_values, fieldset, field, opts)
  end

  defp build_fields_by_type(current_values, _current_schema, fieldset, field, opts) do
    # If type cannot be take from schema, try to infer it from the data

    case Field.get_value(field, fieldset.values) do
      value when is_list(value) ->
        build_fields_for_list(current_values, fieldset, field, opts)

      value when is_map(value) ->
        build_fields_for_object(current_values, fieldset, field, opts)

      _ ->
        []
    end
  end

  defp build_fields_for_list(current_values, fieldset, field, opts) do
    {_index, fields} =
      Enum.reduce(current_values, {0, []}, fn _value, {index, widget_list} ->
        field_path = field.path ++ [index]
        widget = build(fieldset, index, field_path, opts)

        {index + 1, [widget | widget_list]}
      end)

    fields
  end

  defp build_fields_for_object(current_values, fieldset, field, opts) do
    Enum.reduce(current_values, [], fn {field_name, _value}, widget_list ->
      field_path = field.path ++ [field_name]
      widget = build(fieldset, field_name, field_path, opts)
      [widget | widget_list]
    end)
  end

  def build(fieldset, field_name, field_path, opts) do
    field =
      Field.new(field_name, field_path, nil)
      |> build_widget_module(fieldset)
      |> build_sub_fields(fieldset, opts)
      |> build_before_controls(fieldset)
      |> build_after_controls(fieldset)

    field
  end

  defp build_widget_module(field, fieldset) do
    module = Widget.get_widget_module(fieldset, field)
    %{field | widget_module: module}
  end

  defp build_sub_fields(field, fieldset, opts) do
    # Build child fields for lists or objects if this field has those
    sub_fields = build_fields(fieldset, field, opts)
    # Add the sub fields back into the field
    %{field | fields: sub_fields}
  end

  defp build_before_controls(field, fieldset) do
    schema_additions = Field.get_schema_additions(field, fieldset.schema_additions)
    schema = Field.get_schema(field, fieldset.schema)

    # Label
    controls =
      case {field.name, schema_additions} do
        {"", _} ->
          []
        {field_name, %{"include_label" => true}} when is_integer(field_name) ->
          [Control.new(BoldTip.Control.Label)]

        {field_name, _} when is_integer(field_name) ->
          []

        {_, %{"include_label" => false}} ->
          []

        _ ->
          [Control.new(Control.Label)]
      end

    # Remove-button
    controls =
      case {field.path, schema} do
        {[], _} ->
          controls

        {_, nil} ->
          controls

        {_, _schema} ->
          parent_schema =
            field.path
            |> Field.get_parent_path()
            |> Field.get_schema(fieldset.schema)

          case parent_schema do
            nil ->
              controls

            parent_schema ->
              required_fields = Map.get(parent_schema, "required", [])

              if field.name in required_fields do
                controls
              else
                [Control.new(Control.Remove) | controls]
              end
          end
      end

    updated_controls = Map.put(field.controls, :before, Enum.reverse(controls))
    Map.put(field, :controls, updated_controls)
  end

  defp build_after_controls(field, fieldset) do
    schema_additions = Field.get_schema_additions(field, fieldset.schema_additions)
    schema = Field.get_schema(field, fieldset.schema)

    controls = []

    # Errors, skip root field
    controls =
      if fieldset.validated? and not fieldset.valid? and field.name != "" do
        case {schema, schema_additions} do
          {%{"type" => "array"}, _} ->
            controls

          {_, %{"include_errors" => false}} ->
            controls

          _ ->
            case Field.get_errors(field, fieldset.errors) do
              nil ->
                controls

              _ ->
                [Control.new(Control.Errors) | controls]
            end
        end
      else
        controls
      end

    controls =
      case schema do
        %{
          "type" => "object",
          "properties" => _
        } ->
          controls ++ [Control.new(Control.AddField)]

        _ ->
          controls
      end

    updated_controls = Map.put(field.controls, :after, controls)
    Map.put(field, :controls, updated_controls)
  end

  def render_fields(fieldset) do
    fieldset
    |> build_fields([])
    |> Enum.reduce("", fn field, rendered ->
      rendered <> render(fieldset, field)
    end)
  end

  def render_fields(fieldset, root_field) do
    fieldset
    |> build_fields(root_field, [])
    |> Enum.reduce("", fn field, rendered ->
      rendered <> render(fieldset, field)
    end)
  end

  def render(fieldset, field, extra_classes \\ []) do
    before_field =
      field.controls.before
      |> Enum.map(fn control ->
        apply(control.module, :render, [fieldset, field])
      end)
      |> Enum.join("")

    field_render = apply(field.widget_module, :render, [fieldset, field])

    after_field =
      field.controls[:after]
      |> Enum.map(fn control ->
        apply(control.module, :render, [fieldset, field])
      end)
      |> Enum.join("")

    field_markup = Enum.join([before_field, field_render, after_field], "")
    wrap_field(field, fieldset, field_markup, extra_classes)
  end

  def process_value_handlers(fieldset) do
    fieldset
    |> build_fields(nil_required: false)
    |> filter_value_handler_fields()
    |> handle_values(fieldset)
    |> Map.put(:handlers_processed?, true)
  end

  defp filter_value_handler_fields(fields) do
    Enum.reduce(fields, [], fn field, fields ->
      fields = if Widget.has_value_handler?(field.widget_module) do
        [field | fields]
      else
        fields
      end

      if field.fields != [] do
        sub_fields = filter_value_handler_fields(field.fields)
        [sub_fields | fields]
      else
        fields
      end
    end)
    |> Enum.reverse()
    |> List.flatten()
  end

  defp handle_values(fields, fieldset) do
    Enum.reduce(fields, fieldset, fn field, fieldset ->
      case Widget.handle_value(field.widget_module, fieldset, field) do
        {:ok, value} ->
          values = Field.set_value(field, fieldset.values, value)
          %{fieldset | values: values}
        {:error, _error_type, _reason} ->
          raise "error in custom value handling, please implement adding errors to fieldset"
      end
    end)
  end

  def apply_actions(fieldset) do
    fields = build_fields(fieldset, [])
    %{actions: actions} = fieldset

    if length(Map.keys(actions)) > 0 do
      {actions_applied, fieldset} =
        Enum.reduce(actions, {0, fieldset}, fn {field_path, actions}, {applied, fieldset} ->
          if not is_nil(actions) and actions != %{} do
            field = get_field_by_path(fields, field_path)
            # TODO: Fix remove for list item
            case field do
              nil ->
                {applied, fieldset}

              field ->
                {actions_applied, fieldset} = apply_widget_actions(fieldset, field)
                {control_actions_applied, fieldset} = apply_control_actions(fieldset, field)

                {applied + actions_applied + control_actions_applied, fieldset}
            end
          else
            {applied, fieldset}
          end
        end)

      %{fieldset | actions_applied: actions_applied, valid?: false, validated?: false}
    else
      fieldset
    end
  end

  defp apply_widget_actions(fieldset, field) do
    if Widget.has_actions?(field.widget_module) do
      {actions_applied, values} = Widget.handle_actions(field.widget_module, fieldset, field)
      fieldset = %{fieldset | values: values}
      {actions_applied, fieldset}
    else
      {0, fieldset}
    end
  end

  defp apply_control_actions(fieldset, field) do
    controls = field.controls.before ++ field.controls.after

    Enum.reduce(controls, {0, fieldset}, fn control, {actions_applied, fieldset} ->
      if function_exported?(control.module, :actions, 2) do
        {applied, values} = apply(control.module, :actions, [fieldset, field])
        fieldset = %{fieldset | values: values}
        {actions_applied + applied, fieldset}
      else
        {0, fieldset}
      end
    end)
  end

  def get_parent_field(fields, field) do
    parent_path =
      field.path
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()

    get_field_by_path(fields, parent_path)
  end

  defp get_field_by_path([field | _], []), do: field

  # Only get the root field if specifically requested
  defp get_field_by_path([root_field], [""]), do: root_field

  # Skip root field if not fetching it explicitly
  defp get_field_by_path([%Field{name: "", fields: fields}], path),
    do: get_field_by_path(fields, path)

  defp get_field_by_path(current_fields, [next | rest]) do
    field =
      Enum.find(current_fields, nil, fn field ->
        if field.name == next do
          true
        else
          if is_integer(next) do
            field.name == next
          else
            case Integer.parse(next) do
              {position, ""} ->
                field.name == position
              _ -> false
            end
          end
        end
      end)

    case {field, rest} do
      {nil, _} -> nil
      {field, []} -> field
      {%{fields: fields}, rest} -> get_field_by_path(fields, rest)
    end
  end

  defp sort_values([{_, _} | _] = values, schema_additions) do
    Enum.sort(values, fn {field_a, _}, {field_b, _} ->
      ws_a = Map.get(schema_additions, field_a, %{})
      ws_b = Map.get(schema_additions, field_b, %{})

      case {ws_a, ws_b} do
        {%{"weight" => weight_a}, %{"weight" => weight_b}} ->
          weight_a <= weight_b

        {%{"weight" => _}, _} ->
          true

        {_, %{"weight" => _}} ->
          false

        {_, _} ->
          field_a <= field_b
      end
    end)
  end

  defp sort_values(values, _schema_additions) do
    values
  end

  defp add_required_values(values, nil) do
    values
  end

  defp add_required_values(values, schema) do
    schema
    |> Map.get("required", [])
    |> Enum.reduce(values, fn field, values ->
      if is_nil(values) do
        %{field => nil}
      else
        Map.put_new(values, field, nil)
      end

    end)
  end

  EEx.function_from_string(
    :defp,
    :wrap_field,
    """
    <div class="<%= Base.wrapper_classes(field, fieldset, extra_classes) %>">
    <%= contents %>
    </div>
    """,
    [:field, :fieldset, :contents, :extra_classes]
  )
end
