defmodule BoldTip do
  @moduledoc """
  This library generates, processes and validates HTML forms based on a JSON
  Schema. By using this library with an existing JSON Schema you can get an
  instant UI for generating new values according to the schema. So if you
  have an API endpoint or other JSON Schema in your life where you want some
  old reliable HTML forms to work with it, Bold Tip can do that for you.

  Additionally it offers extended widgets for some types, such as a extending
  a string to be a file upload procedure. Or rendering a date picker with JS
  for a date-time field. All JS is optional but strongly recommended. See the
  Javascript and CSS docs for more on that.

  ## Examples

  The basic usage for rendering a brand new form from some values
  and a schema is:

  iex> my_schema = %{
  ...>  "type" => "object",
  ...>  "properties" => %{
  ...>    "name" => %{"type" => "string"},
  ...>    "attending" => %{"type" => "boolean"}
  ...>  },
  ...>  "required" => ["name"]
  ...>}
  iex> values = %{"name" => "Underjord"}
  iex> html = values
  ...> |> BoldTip.fieldset_from_values(my_schema)
  ...> |> BoldTip.render_fields()
  iex> html =~ "value--name"
  true

  Handling form submission has more moving parts and gets a bit more complex.

  iex> my_schema = %{
  ...>  "type" => "object",
  ...>  "properties" => %{
  ...>    "name" => %{"type" => "string"},
  ...>    "attending" => %{"type" => "boolean"}
  ...>  },
  ...>  "required" => ["name"]
  ...> }
  iex> params = %{"value--name" => "Underjord"}
  iex> fieldset = params
  ...> |> BoldTip.fieldset_from_params(my_schema)
  ...> |> BoldTip.validate_fields()
  ...> |> BoldTip.apply_actions()
  iex> fieldset.validated?
  true
  iex> fieldset.valid?
  true
  iex> fieldset.actions_applied
  0
  iex> fieldset.values
  %{"name" => "Underjord"}

  If the fieldset doesn't end up valid or if actions were applied you would
  want to render it again to show errors or changes from actions.

  """

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
