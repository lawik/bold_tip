defmodule BoldTip.Control.Errors do
  require EEx
  # import BoldTip.Widget.Base
  alias BoldTip.Fields.Field

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="boldtip-control boldtip-control-errors">
        <%= inspect(errors) %> (TODO: nicer errors)
    </div>
    """,
    [:errors]
  )

  def render(fieldset, field) do
    errors = Field.get_errors(field, fieldset.errors)
    template(errors)
  end
end
