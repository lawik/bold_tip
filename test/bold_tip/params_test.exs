defmodule BoldTip.ParamsTest do
  use ExUnit.Case

  alias BoldTip.Params

  @full_params %{
    "value--a_string_field" => "foo",
    "value--a_boolean_field" => "true",
    "value--an_integer_field" => "1337",
    "value--an_array_with_string_items--0" => "string_1",
    "value--an_array_with_string_items--1" => "string_2",
    "value--an_object--a_string_field" => "foo",
    "value--an_object--a_boolean_field" => "true",
    "value--an_object--an_integer_field" => "1337",
    "value--an_array_with_object_items--0--a_string_field" => "foo",
    "value--an_array_with_object_items--0--a_boolean_field" => "true",
    "value--an_array_with_object_items--0--an_integer_field" => "1337",
    "value--an_array_with_object_items--1--a_string_field" => "foo2",
    "value--an_array_with_object_items--1--a_boolean_field" => "false",
    "value--an_array_with_object_items--1--an_integer_field" => "7331",
    "action--an_array_with_object_items--1--an_integer_field---increment" => "Increment",
    "action--an_array_with_object_items--1--an_integer_field---remove" => "Remove",
    "action--a_string_field---append-bar" => "foo"
  }

  @addition_params %{
    "value--a_string_field" => :value_params_cant_handle,
    "value--a_boolean_field" => "true",
    "value--an_integer_field" => "1337",
    "value--an_array_with_string_items--0" => "string_1",
    "value--an_array_with_string_items--1" => "string_2",
    "value--an_object--a_string_field" => "foo",
    "value--an_object--a_boolean_field" => "true",
    "value--an_object--an_integer_field" => "1337",
    "value--an_array_with_object_items--0--a_string_field" => "foo",
    "value--an_array_with_object_items--0--a_boolean_field" => "true",
    "value--an_array_with_object_items--0--an_integer_field" => "1337",
    "value--an_array_with_object_items--1--a_string_field" => "foo2",
    "value--an_array_with_object_items--1--a_boolean_field" => "false",
    "value--an_array_with_object_items--1--an_integer_field" => "7331",
    "action--an_array_with_object_items--1--an_integer_field---increment" => "Increment",
    "action--an_array_with_object_items--1--an_integer_field---remove" => "Remove",
    "action--a_string_field---append-bar" => "foo"
  }

  @full_values %{
    "a_string_field" => "foo",
    "a_boolean_field" => true,
    "an_integer_field" => 1337,
    "an_array_with_string_items" => [
      "string_1",
      "string_2"
    ],
    "an_object" => %{
      "a_string_field" => "foo",
      "a_boolean_field" => true,
      "an_integer_field" => 1337
    },
    "an_array_with_object_items" => [
      %{
        "a_string_field" => "foo",
        "a_boolean_field" => true,
        "an_integer_field" => 1337
      },
      %{
        "a_string_field" => "foo2",
        "a_boolean_field" => false,
        "an_integer_field" => 7331
      }
    ]
  }

  @addition_values %{
    "a_string_field" => :value_params_cant_handle,
    "a_boolean_field" => true,
    "an_integer_field" => 1337,
    "an_array_with_string_items" => [
      "string_1",
      "string_2"
    ],
    "an_object" => %{
      "a_string_field" => "foo",
      "a_boolean_field" => true,
      "an_integer_field" => 1337
    },
    "an_array_with_object_items" => [
      %{
        "a_string_field" => "foo",
        "a_boolean_field" => true,
        "an_integer_field" => 1337
      },
      %{
        "a_string_field" => "foo2",
        "a_boolean_field" => false,
        "an_integer_field" => 7331
      }
    ]
  }

  # @full_actions %{
  #   ["an_array_with_object_items", 1, "an_integer_field"] => ["increment", "remove"],
  #   ["a_string_field"] => ["append-bar"]
  # }

  @full_schema %{
    "type" => "object",
    "properties" => %{
      "a_string_field" => %{"type" => "string"},
      "a_boolean_field" => %{"type" => "boolean"},
      "an_integer_field" => %{"type" => "integer"},
      "an_array_with_string_items" => %{
        "type" => "array",
        "items" => %{"type" => "string"}
      },
      "an_object" => %{
        "type" => "object",
        "properties" => %{
          "a_string_field" => %{"type" => "string"},
          "a_boolean_field" => %{"type" => "boolean"},
          "an_integer_field" => %{"type" => "integer"}
        }
      },
      "an_array_with_object_items" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "properties" => %{
            "a_string_field" => %{"type" => "string"},
            "a_boolean_field" => %{"type" => "boolean"},
            "an_integer_field" => %{"type" => "integer"}
          }
        }
      }
    }
  }

  @additions %{
    "a_string_field" => %{
      "widget" => "file"
    }
  }

  describe "params to values" do
    test "simple param" do
      %{
        values_prefix: prefix,
        separator: separator
      } = BoldTip.default_options()

      field_name = "myfield"
      # Build name as it would be used in the form
      value_name = Params.fieldpath_to_paramkey([field_name], prefix, separator)
      # Create a params map
      params = %{
        value_name => "foo"
      }

      # Create a basic JSON schema for this structure
      schema = %{
        "type" => "object",
        "properties" => %{
          field_name => %{
            "type" => "string"
          }
        }
      }

      # Check that value parsing was successful
      assert %{
               values: %{
                 ^field_name => "foo"
               }
             } = BoldTip.fieldset_from_params(params, schema)
    end

    test "full set" do
      # Check that value parsing was successful
      assert %{values: @full_values} = BoldTip.fieldset_from_params(@full_params, @full_schema)
    end

    test "full set with custom value" do
      # Check that value parsing was successful
      assert %{values: @addition_values} = BoldTip.fieldset_from_params(@addition_params, @full_schema, @additions)
    end
  end

  describe "params to actions" do
    test "decent set" do
      assert %{actions: full_actions} = BoldTip.fieldset_from_params(@full_params, @full_schema)
    end
  end
end
