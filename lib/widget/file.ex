defmodule BoldTip.Widget.File do
  require EEx
  import BoldTip.Widget.Base
  alias BoldTip.Fields.Field
  alias BoldTip.Fieldset
  alias BoldTip.Widget

  @behaviour Widget
  def type, do: {"string","file"}

  EEx.function_from_string(
    :defp,
    :template,
    """
    <div class="<%= classes(__MODULE__, field.path, fieldset) %>">
      <%= if not is_nil(value) and value != "" do %>
        <div class="filename"><%= value %></div>
        <input
          type="hidden"
          id="<%= id(field.path, fieldset.options) %>"
          name="<%= name(field.path, fieldset.options) %>"
          value="<%= value %>"
          />
        <input type="submit" name="<%= action(field.path, "remove", fieldset.options) %>" value="Remove file" />
      <% else %>
        <input
          type="file"
          id="<%= id(field.path, fieldset.options) %>"
          name="<%= name(field.path, fieldset.options) %>"
          />
          <input type="submit" name="<%= action(field.path, "upload", fieldset.options) %>" value="Upload file" />
      <% end %>
    </div>
    """,
    [:fieldset, :field, :value]
  )

  def render(fieldset, field) do
    value =
      field
      |> Field.get_value(fieldset.values)
      |> default_value()

    template(fieldset, field, value)
  end

  def handle_value(fieldset, field) do
    value = Field.get_value(field, fieldset.values)
    case Fieldset.get_handler(fieldset, __MODULE__) do
      nil -> {:error, :no_handler_defined, "No handler defined to handle file uploads for #{inspect(field.path)}."}
      handler ->
        case value do
          %{filename: _, path: _} ->
            case handler.(fieldset, field, value) do
              {:copy, working_dir, target_directory} ->
                case process_file_upload(value, target_directory) do
                  {:ok, filepath} -> {:ok, Path.relative_to(filepath, working_dir)}
                  {:error, reason} -> {:error, :file_processing_failed, "An error occurred processing your file upload: #{reason}"}
                end
              {:handled, filepath} ->
                {:ok, filepath}
            end
          value when is_binary(value) -> {:ok, value}
        end
    end
  end

  defp process_file_upload(file, target_directory) do
    if File.exists?(file.path) do
      filepath = available_filepath(target_directory, file.filename)
      IO.inspect("copying from #{file.path} to #{filepath}")
      File.cp!(file.path, filepath)
      {:ok, filepath}
    else
      {:error, :file_upload_not_found, "Something went wrong with the upload."}
    end
  end

  defp available_filepath(target_directory, filename, attempt \\ 0) do
    new_filename = case attempt do
      0 -> filename
      attempt ->
        basename = Path.basename(filename)
        extension = Path.extname(filename)
        "#{basename}-#{attempt}#{extension}"
    end

    filepath = Path.join(target_directory, new_filename)
    if File.exists?(filepath) do
      available_filepath(target_directory, filename, attempt+1)
    else
      filepath
    end
  end

  defp default_value(nil), do: ""
  defp default_value(value), do: value
end
