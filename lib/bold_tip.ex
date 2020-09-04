defmodule BoldTip do
  alias BoldTip.Fields
  alias BoldTip.Fieldset

  @default_options %{
    values_prefix: "value",
    actions_prefix: "action",
    separator: "--",
    section_separator: "---",
    widget_handlers: %{}
  }

  def fieldset_from_values(values, schema, schema_additions \\ %{}, options \\ %{}) do
    Fieldset.from_values(values, schema, schema_additions, options)
  end

  def fieldset_from_params(params, schema, schema_additions \\ %{}, options \\ %{}) do
    Fieldset.from_params(params, schema, schema_additions, options)
  end

  def render_fields(fieldset) do
    Fields.render_fields(fieldset)
  end

  def validate_fields(fieldset) do
    %{
      handlers: handlers,
      schema: schema,
      values: values,
      handlers_processed?: handlers_processed?
    } = fieldset
    if handlers != %{} and not handlers_processed? do
      raise "Could not start validation, handlers set without being processed. Call BoldTip.Fieldset.process_handlers(fieldset) explicitly."
    end
    json_schema = JsonXema.new(schema)

    case JsonXema.validate(json_schema, values) do
      :ok -> %{fieldset | valid?: true, validated?: true}
      {:error, reasons} -> %{fieldset | valid?: false, errors: reasons, validated?: true}
    end
  end

  def apply_actions(%{actions: actions} = fieldset) when actions == %{} do
    %{fieldset | actions_applied: 0}
  end

  def apply_actions(fieldset) do
    Fields.apply_actions(fieldset)
  end

  def default_options do
    @default_options
  end
end
