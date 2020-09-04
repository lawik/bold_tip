defmodule BoldTip.Fieldset do
  defstruct schema: %{},
            values: %{},
            actions: %{},
            schema_additions: %{},
            options: %{},
            handlers: %{},
            handlers_processed?: false,
            valid?: false,
            validated?: false,
            errors: %{},
            actions_applied: 0

  alias BoldTip.Fields
  alias BoldTip.Params

  def from_values(values, schema, schema_additions \\ %{}, options \\ %{}) do
    %BoldTip.Fieldset{
      schema: schema,
      schema_additions: schema_additions,
      values: values,
      options: Map.merge(BoldTip.default_options(), options)
    }
  end

  def from_params(params, schema, schema_additions \\ %{}, options \\ %{}) do
    options = Map.merge(BoldTip.default_options(), options)
    values = Params.params_to_values(params, schema, schema_additions, options)
    actions = Params.params_to_actions(params, options)

    %BoldTip.Fieldset{
      schema: schema,
      schema_additions: schema_additions,
      values: values,
      actions: actions,
      options: Map.merge(BoldTip.default_options(), options)
    }
  end

  def process_handlers(fieldset) do
    Fields.process_value_handlers(fieldset)
  end

  def set_handler(fieldset, widget, handler_function) do
    handlers = Map.put(fieldset.handlers, widget, handler_function)
    %{fieldset | handlers: handlers}
  end

  def get_handler(%{handlers: handlers} = _fieldset, widget) do
    Map.get(handlers, widget, nil)
  end

  # TODO
  # def add_error(fieldset, field, error) do
  #   %{errors: errors} = fieldset
  #   errors = [error | errors]
  #   %{fieldset | errors: errors}
  # end
end
