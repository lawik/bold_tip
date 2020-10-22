defmodule BoldTip.FieldsTest do
  use ExUnit.Case

  # @full_params %{
  #   "value--aStringField" => "foo",
  #   "value--aBooleanField" => "true",
  #   "value--anIntegerField" => "1337",
  #   "value--anArrayWithStringItems--0" => "string_1",
  #   "value--anArrayWithStringItems--1" => "string_2",
  #   "value--anObject--aStringField" => "foo",
  #   "value--anObject--aBooleanField" => "true",
  #   "value--anObject--anIntegerField" => "1337",
  #   "value--anArrayWithObjectItems--0--aStringField" => "foo",
  #   "value--anArrayWithObjectItems--0--aBooleanField" => "true",
  #   "value--anArrayWithObjectItems--0--anIntegerField" => "1337",
  #   "value--anArrayWithObjectItems--1--aStringField" => "foo2",
  #   "value--anArrayWithObjectItems--1--aBooleanField" => "false",
  #   "value--anArrayWithObjectItems--1--anIntegerField" => "7331",
  #   "action--anArrayWithObjectItems--1--an_integer_value---increment" => "Increment",
  #   "action--anArrayWithObjectItems--1--an_integer_value---remove" => "Remove",
  #   "action--a_string_value---append-bar" => "foo"
  # }

  @full_values %{
    "aStringField" => "foo",
    "aBooleanField" => true,
    "anIntegerField" => 1337,
    "anArrayWithStringItems" => [
      "string_1",
      "string_2"
    ],
    "anObject" => %{
      "aStringField" => "foo",
      "aBooleanField" => true,
      "anIntegerField" => 1337
    },
    "anArrayWithObjectItems" => [
      %{
        "aStringField" => "foo",
        "aBooleanField" => true,
        "anIntegerField" => 1337
      },
      %{
        "aStringField" => "foo2",
        "aBooleanField" => false,
        "anIntegerField" => 7331
      }
    ]
  }

  # @full_actions %{
  #   ["anArrayWithObjectItems", 1, "anIntegerField"] => ["increment", "remove"],
  #   ["aStringField"] => ["append-bar"]
  # }

  @full_schema %{
    "type" => "object",
    "properties" => %{
      "aStringField" => %{"type" => "string"},
      "aBooleanField" => %{"type" => "boolean"},
      "anIntegerField" => %{"type" => "integer"},
      "aStringEnum" => %{"type" => "string", "enum" => ["foo", "bar"]},
      "anArrayWithStringItems" => %{
        "type" => "array",
        "items" => %{"type" => "string"}
      },
      "anObject" => %{
        "type" => "object",
        "properties" => %{
          "aStringField" => %{"type" => "string"},
          "aBooleanField" => %{"type" => "boolean"},
          "anIntegerField" => %{"type" => "integer"}
        }
      },
      "anArrayWithObjectItems" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "properties" => %{
            "aStringField" => %{"type" => "string"},
            "aBooleanField" => %{"type" => "boolean"},
            "anIntegerField" => %{"type" => "integer"}
          }
        }
      }
    }
  }

  defp sch(props) do
    %{
      "type" => "object",
      "properties" => props
    }
  end

  describe "fields" do
    test "string field" do
      schema =
        sch(%{
          "aStringField" => %{"type" => "string"}
        })

      values = %{
        "aStringField" => "foo"
      }

      fieldset = BoldTip.fieldset_from_values(values, schema)
      rendered = BoldTip.render_fields(fieldset)

      assert [
               {
                 "div",
                 [{"class", "boldtip-component"}],
                 [
                   {
                     "div",
                     [{"class", "boldtip-field boldtip-field-composite"}],
                     [
                       {"div", [{"class", "boldtip-component boldtip-field-composite-subfield"}],
                        [
                          {"div", [{"class", "boldtip-control boldtip-control-label"}],
                           [
                             {"label", [{"class", "boldtip-label"}, {"for", "id--aStringField"}],
                              ["A String Field"]}
                           ]},
                          {"div", [{"class", "boldtip-control boldtip-control-remove"}],
                           [
                             {"input",
                              [
                                {"type", "submit"},
                                {"class", "remove"},
                                {"name", "action--aStringField---remove-field"},
                                {"value", "Remove"}
                              ], []}
                           ]},
                          {"div", [{"class", "boldtip-field boldtip-field-string"}],
                           [
                             {"input",
                              [
                                {"type", "text"},
                                {"id", "id--aStringField"},
                                {"name", "value--aStringField"},
                                {"value", "foo"}
                              ], []}
                           ]}
                        ]}
                     ]
                   }
                 ]
               }
             ] = Floki.parse_fragment!(rendered)
    end

    test "string enum field" do
      schema =
        sch(%{
          "aStringField" => %{"type" => "string", "enum" => ["foo", "bar"]}
        })

      values = %{
        "aStringField" => "foo"
      }

      fieldset = BoldTip.fieldset_from_values(values, schema)
      rendered = BoldTip.render_fields(fieldset)

      assert [
               {
                 "div",
                 [{"class", "boldtip-component"}],
                 [
                   {
                     "div",
                     [{"class", "boldtip-field boldtip-field-composite"}],
                     [
                       {"div", [{"class", "boldtip-component boldtip-field-composite-subfield"}],
                        [
                          {"div", [{"class", "boldtip-control boldtip-control-label"}],
                           [
                             {"label", [{"class", "boldtip-label"}, {"for", "id--aStringField"}],
                              ["A String Field"]}
                           ]},
                          {"div", [{"class", "boldtip-control boldtip-control-remove"}],
                           [
                             {"input",
                              [
                                {"type", "submit"},
                                {"class", "remove"},
                                {"name", "action--aStringField---remove-field"},
                                {"value", "Remove"}
                              ], []}
                           ]},
                          {"div", [{"class", "boldtip-field boldtip-field-select"}],
                           [
                             {"select",
                              [
                                {"type", "text"},
                                {"id", "id--aStringField"},
                                {"name", "value--aStringField"}
                              ],
                              [
                                {"option", [{"value", "foo"}, {"selected", "selected"}], ["foo"]},
                                {"option", [{"value", "bar"}], ["bar"]}
                              ]}
                           ]}
                        ]}
                     ]
                   }
                 ]
               }
             ] = Floki.parse_fragment!(rendered)
    end

    test "string field should show add field" do
      schema =
        sch(%{
          "aStringField" => %{"type" => "string"},
          "anotherStringField" => %{"type" => "string"}
        })

      values = %{
        "aStringField" => "foo"
      }

      fieldset = BoldTip.fieldset_from_values(values, schema)
      rendered = BoldTip.render_fields(fieldset)

      assert [
               {
                 "div",
                 [{"class", "boldtip-component"}],
                 [
                   {
                     "div",
                     [{"class", "boldtip-field boldtip-field-composite"}],
                     [
                       {"div", [{"class", "boldtip-component boldtip-field-composite-subfield"}],
                        [
                          {"div", [{"class", "boldtip-control boldtip-control-label"}],
                           [
                             {"label", [{"class", "boldtip-label"}, {"for", "id--aStringField"}],
                              ["A String Field"]}
                           ]},
                          {"div", [{"class", "boldtip-control boldtip-control-remove"}],
                           [
                             {"input",
                              [
                                {"type", "submit"},
                                {"class", "remove"},
                                {"name", "action--aStringField---remove-field"},
                                {"value", "Remove"}
                              ], []}
                           ]},
                          {"div", [{"class", "boldtip-field boldtip-field-string"}],
                           [
                             {"input",
                              [
                                {"type", "text"},
                                {"id", "id--aStringField"},
                                {"name", "value--aStringField"},
                                {"value", "foo"}
                              ], []}
                           ]}
                        ]}
                     ]
                   },
                   {"div", [{"class", "boldtip-control boldtip-control-addfield"}],
                    [
                      {"label", [{"for", "id----toggle"}, {"class", "meta-add-field-label"}],
                       ["Add field"]},
                      {"input",
                       [
                         {"id", "id----toggle"},
                         {"class", "meta-add-field"},
                         {"type", "checkbox"},
                         {"name", "id(field.path, fieldset.options, "},
                         {"toggle-ignore\")\"", "toggle-ignore\")\""},
                         {"value", "1"}
                       ], []},
                      {"div", [{"class", "add-field-selector"}],
                       [
                         {"div", [{"class", "add-field"}],
                          [
                            {"p", [], [{"strong", [], ["Another String Field"]}, {"br", [], []}]},
                            {"input",
                             [
                               {"class", "button-outline"},
                               {"name", "action-----add-field-anotherStringField"},
                               {"type", "submit"},
                               {"value", "Add"}
                             ], []}
                          ]}
                       ]}
                    ]}
                 ]
               }
             ] = Floki.parse_fragment!(rendered)
    end

    test "integer field" do
      schema =
        sch(%{
          "anIntegerField" => %{"type" => "integer"}
        })

      values = %{
        "anIntegerField" => "123"
      }

      fieldset = BoldTip.fieldset_from_values(values, schema)
      rendered = BoldTip.render_fields(fieldset)

      assert [
               {
                 "div",
                 [{"class", "boldtip-component"}],
                 [
                   {
                     "div",
                     [{"class", "boldtip-field boldtip-field-composite"}],
                     [
                       {"div", [{"class", "boldtip-component boldtip-field-composite-subfield"}],
                        [
                          {"div", [{"class", "boldtip-control boldtip-control-label"}],
                           [
                             {"label",
                              [{"class", "boldtip-label"}, {"for", "id--anIntegerField"}],
                              ["An Integer Field"]}
                           ]},
                          {"div", [{"class", "boldtip-control boldtip-control-remove"}],
                           [
                             {"input",
                              [
                                {"type", "submit"},
                                {"class", "remove"},
                                {"name", "action--anIntegerField---remove-field"},
                                {"value", "Remove"}
                              ], []}
                           ]},
                          {"div", [{"class", "boldtip-field boldtip-field-integer"}],
                           [
                             {"input",
                              [
                                {"type", "number"},
                                {"id", "id--anIntegerField"},
                                {"name", "value--anIntegerField"},
                                {"value", "123"}
                              ], []}
                           ]}
                        ]}
                     ]
                   }
                 ]
               }
             ] = Floki.parse_fragment!(rendered)
    end

    # TODO: List widget for array type, with actions
    # TODO: Object/composite, with actions

    test "full set, no widget settings" do
      # Can render at all
      fieldset = BoldTip.fieldset_from_values(@full_values, @full_schema)
      assert rendered = BoldTip.render_fields(fieldset)
    end

    test "nested structure, validation errors" do
      schema =
        sch(%{
          "aDateTime" => %{
            "type" => "string",
            "format" => "date-time"
          },
          "anArrayOfDatetimes" => %{
            "type" => "array",
            "items" => %{
              "type" => "string",
              "format" => "date-time"
            }
          }
        })

      values = %{
        "aDateTime" => "2020-05-16T20:50:00+02:00555",
        "anArrayOfDatetimes" => ["fnork", "fnork2"]
      }

      fieldset =
        values
        |> BoldTip.fieldset_from_values(schema)
        |> BoldTip.validate_fields()

      assert %{validated?: true, valid?: false, errors: errors} = fieldset
      rendered = BoldTip.render_fields(fieldset)

      assert [
               {
                 "div",
                 [{"class", "boldtip-component"}],
                 [
                   {
                     "div",
                     [{"class", "boldtip-field boldtip-field-composite"}],
                     [
                       {"div", [{"class", "boldtip-component boldtip-field-composite-subfield"}],
                        [
                          {"div", [{"class", "boldtip-control boldtip-control-label"}],
                           [
                             {"label", [{"class", "boldtip-label"}, {"for", "id--aDateTime"}],
                              ["A Date Time"]}
                           ]},
                          {"div", [{"class", "boldtip-control boldtip-control-remove"}],
                           [
                             {"input",
                              [
                                {"type", "submit"},
                                {"class", "remove"},
                                {"name", "action--aDateTime---remove-field"},
                                {"value", "Remove"}
                              ], []}
                           ]},
                          {"div", [{"class", "boldtip-field boldtip-field-datetime"}],
                           [
                             {"input",
                              [
                                {"type", "text"},
                                {"id", "id--aDateTime"},
                                {"name", "value--aDateTime"},
                                {"value", "2020-05-16T20:50:00+02:00555"}
                              ], []}
                           ]},
                          {"div", [{"class", "boldtip-control boldtip-control-errors"}],
                           [
                             "\n    %{format: \"date-time\", value: \"2020-05-16T20:50:00+02:00555\"} (TODO: nicer errors)\n"
                           ]}
                        ]},
                       {"div", [{"class", "boldtip-component boldtip-field-composite-subfield"}],
                        [
                          {"div", [{"class", "boldtip-control boldtip-control-label"}],
                           [
                             {"label",
                              [{"class", "boldtip-label"}, {"for", "id--anArrayOfDatetimes"}],
                              ["An Array Of Datetimes"]}
                           ]},
                          {"div", [{"class", "boldtip-control boldtip-control-remove"}],
                           [
                             {"input",
                              [
                                {"type", "submit"},
                                {"class", "remove"},
                                {"name", "action--anArrayOfDatetimes---remove-field"},
                                {"value", "Remove"}
                              ], []}
                           ]},
                          {"div", [{"class", "boldtip-field boldtip-field-list"}],
                           [
                             {"input",
                              [
                                {"type", "hidden"},
                                {"name", "value--anArrayOfDatetimes"},
                                {"value", "empty-list"}
                              ], []},
                             {"div",
                              [
                                {"class", "boldtip-field-list-items"},
                                {"id", "id--anArrayOfDatetimes"}
                              ],
                              [
                                {"div", [{"class", "boldtip-component boldtip-field-list-item"}],
                                 [
                                   {"div", [{"class", "boldtip-control boldtip-control-remove"}],
                                    [
                                      {"input",
                                       [
                                         {"type", "submit"},
                                         {"class", "remove"},
                                         {"name", "action--anArrayOfDatetimes--0---remove-field"},
                                         {"value", "Remove"}
                                       ], []}
                                    ]},
                                   {"div", [{"class", "boldtip-field boldtip-field-datetime"}],
                                    [
                                      {"input",
                                       [
                                         {"type", "text"},
                                         {"id", "id--anArrayOfDatetimes--0"},
                                         {"name", "value--anArrayOfDatetimes--0"},
                                         {"value", "fnork"}
                                       ], []}
                                    ]},
                                   {"div", [{"class", "boldtip-control boldtip-control-errors"}],
                                    [
                                      "\n    %{format: \"date-time\", value: \"fnork\"} (TODO: nicer errors)\n"
                                    ]}
                                 ]},
                                {"div", [{"class", "boldtip-component boldtip-field-list-item"}],
                                 [
                                   {"div", [{"class", "boldtip-control boldtip-control-remove"}],
                                    [
                                      {"input",
                                       [
                                         {"type", "submit"},
                                         {"class", "remove"},
                                         {"name", "action--anArrayOfDatetimes--1---remove-field"},
                                         {"value", "Remove"}
                                       ], []}
                                    ]},
                                   {"div", [{"class", "boldtip-field boldtip-field-datetime"}],
                                    [
                                      {"input",
                                       [
                                         {"type", "text"},
                                         {"id", "id--anArrayOfDatetimes--1"},
                                         {"name", "value--anArrayOfDatetimes--1"},
                                         {"value", "fnork2"}
                                       ], []}
                                    ]},
                                   {"div", [{"class", "boldtip-control boldtip-control-errors"}],
                                    [
                                      "\n    %{format: \"date-time\", value: \"fnork2\"} (TODO: nicer errors)\n"
                                    ]}
                                 ]},
                                {"input",
                                 [
                                   {"type", "submit"},
                                   {"name", "action--anArrayOfDatetimes---add-item"},
                                   {"value", "Add item"}
                                 ], []}
                              ]}
                           ]}
                        ]}
                     ]
                   }
                 ]
               }
             ] = Floki.parse_fragment!(rendered)
    end
  end
end
