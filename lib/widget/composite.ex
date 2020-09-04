defmodule BoldTip.Widget.Composite do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Widget

  @behaviour Widget
  def type, do: {"object","composite"}

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="<%= classes(__MODULE__, field.path, fieldset) %>"
      <%= if field.path != [] do %>
       id="<%= id(field.path, fieldset.options) %>"
      <% end %>
    >
    <%= for sub_field <- sub_fields do %>
      <%= sub_field %>
    <% end %>
    </div>
    """,
    [:fieldset, :field, :sub_fields]
  )

  def render(fieldset, field) do
    sub_fields = render_child_fields(fieldset, field, "boldtip-field-composite-subfield")
    template(fieldset, field, sub_fields)
  end

end
