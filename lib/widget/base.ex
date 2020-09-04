defmodule BoldTip.Widget.Base do
  alias BoldTip.Fields.Field
  def path_string(path, options), do: Enum.join(path, options.separator)

  def classes(widget_module, _path, _fieldset, extra_classes \\ []) do
    widget = Atom.to_string(widget_module) |> String.split(".") |> List.last() |> String.downcase()

    classes = ["boldtip-field", "boldtip-field-#{widget}"] ++ extra_classes
    Enum.join(classes, " ")
  end

  def wrapper_classes(field, %{schema_additions: schema_additions} = _fieldset, extra_classes) do
    schema_additions = Field.get_schema_additions(field, schema_additions)
    classes = ["boldtip-component" | extra_classes]
    classes = if schema_additions["groupable"] do
      ["boldtip-component-groupable" | classes]
    else
      classes
    end
    Enum.join(classes, " ")
  end

  def field([], _), do: ""

  def field(path, options), do: "field#{options.separator}#{path_string(path, options)}"

  def field(path, options, suffix),
    do: "field#{options.separator}#{path_string(path, options)}#{options.separator}#{suffix}"

  def id([], _), do: ""
  def id(path, options), do: "id#{options.separator}#{path_string(path, options)}"

  def id(path, options, suffix),
    do: "id#{options.separator}#{path_string(path, options)}#{options.separator}#{suffix}"

  def name(path, options),
    do: "#{options.values_prefix}#{options.separator}#{path_string(path, options)}"

  def name(path, options, suffix),
    do:
      "#{options.values_prefix}#{options.separator}#{path_string(path, options)}#{
        options.separator
      }#{suffix}"

  def action("", key, action_name, options) do
    "#{options.actions_prefix}#{options.separator}#{key}#{options.section_separator}#{action_name}"
  end

  def action("", key, action_name, options, suffix) do
    "#{options.actions_prefix}#{options.separator}#{key}#{options.separator}#{suffix}#{
      options.section_separator
    }#{action_name}"
  end

  def action(path, action_name, options) do
    "#{options.actions_prefix}#{options.separator}#{path_string(path, options)}#{
      options.section_separator
    }#{action_name}"
  end

  def child_prefix(field_name, "", _separator), do: field_name
  def child_prefix(field_name, prefix, separator), do: "#{prefix}#{separator}#{field_name}"

  def render_child_fields(fieldset, field, class) do
    Enum.map(field.fields, fn child_field ->
      BoldTip.Fields.render(fieldset, child_field, [class])
    end)
  end
end
