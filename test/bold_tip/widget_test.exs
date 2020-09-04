defmodule BoldTip.WidgetTest do
  use ExUnit.Case

  alias BoldTip.Fieldset

  # Lifted from a project as it is a good, real and decently complex schema
  @base_schema %{
    "$schema" => "http://json-schema.org/draft-07/schema#",
    "$id" => "",
    "title" => "Hugo type schema",
    "description" => "",
    "type" => "object",
    "properties" => %{
      # Documentation on these variables:
      # https://gohugo.io/content-management/front-matter/#front-matter-variables
      "title" => %{
        "type" => "string"
      },
      "slug" => %{
        "type" => "string",
        "pattern" => "[-a-zA-Z0-9]+",
        "description" => "A URL-friendly name for use in links, must be unique per type."
      },
      "date" => %{
        "type" => "string",
        "format" => "date-time",
        "description" => "Display date and time."
      },
      "draft" => %{
        "type" => "boolean",
        "description" => "Draft status, whether it is ready to publish or not."
      },
      # Not a Hugo Front Matter variable, the actual document body
      "body" => %{"type" => "string"},

      # Optionals
      "categories" => %{
        "type" => "array",
        "items" => %{"type" => "string"},
        "description" => "Generally used for structured organisation of content."
      },
      "tags" => %{
        "type" => "array",
        "items" => %{"type" => "string"},
        "description" => "Generally used for unstructured marking of content."
      },
      "aliases" => %{
        "type" => "array",
        "items" => %{"type" => "string"},
        "description" => "Additional link URLs where this content should be made available."
      },
      "audio" => %{
        "type" => "array",
        "items" => %{"type" => "string"},
        "description" => "Used to reference audio files in OpenGraph."
      },
      "cascade" => %{
        "type" => "object",
        "description" => "Fields that should be inherited by descendents of this page."
      },
      "expireDate" => %{
        "type" => "string",
        "format" => "date-time",
        "description" =>
          "A date and time for when the content should no longer be published in successive publishings. Depending on your site configuration this may or may not be automatic."
      },
      "headless" => %{
        "type" => "boolean",
        "description" =>
          "This piece of content should not be published on the site and will not have a permalink. It could still be used by a theme or via API."
      },
      "images" => %{
        "type" => "array",
        "items" => %{"type" => "string"},
        "description" =>
          "Images related to the path, used by internal templates, such as Twitter Cards."
      },
      "isCJKLanguage" => %{
        "type" => "boolean",
        "description" =>
          "Explicitly treat as a CJK language (Chinese, Japanese, Korean). Will make summary and wordcounts behave correctly for CJK languages."
      },
      "keywords" => %{
        "type" => "string",
        "description" => "Meta keywords for this page."
      },
      "layout" => %{
        "type" => "string",
        "description" => "Override what layout is used to render the content."
      },
      "lastmod" => %{
        "type" => "string",
        "format" => "date-time",
        "description" => "Date and time for the latest edit."
      },
      "linkTitle" => %{
        "type" => "string",
        "description" => "Overrides the title used when linking to this piece of content."
      },
      "outputs" => %{
        "type" => "array",
        "items" => %{"type" => "string"},
        "description" => "Specify output formats specific to this piece of content."
      },
      "publishDate" => %{
        "type" => "string",
        "format" => "date-time",
        "description" =>
          "Will not be published before this time. Depending on your site configuration publishing at this date and time might not be automatic."
      },
      "resources" => %{
        "type" => "array",
        "items" => %{
          "type" => "object",
          "properties" => %{
            "name" => %{"type" => "string"},
            "src" => %{"type" => "string"},
            "title" => %{"type" => "string"},
            "params" => %{
              "type" => "object",
              "additionalProperties" => true
            }
          },
          "required" => ["src"]
        },
        "description" =>
          "Details related resources connected to the content item, generally additional files and their metadata."
      },
      "series" => %{
        "type" => "array",
        "items" => %{"type" => "string"},
        "description" =>
          "List of series that this content is part of. Series must be defined as a taxonomy. Used by Open Graph for see_also field."
      },
      "summary" => %{
        "type" => "string",
        "description" => "Text summary of the content."
      },
      "type" => %{
        "type" => "string",
        "description" => "Override content type."
      },
      "url" => %{
        "type" => "string",
        "description" => "Override URL path entirely. Ignores any language prefixes."
      },
      "videos" => %{
        "type" => "array",
        "items" => %{"type" => "string"},
        "description" => "List of related videos. Used by Open Graph for the video field."
      },
      "weight" => %{
        "type" => "integer",
        "description" =>
          "Used to order content in lists. Lower weight lands higher up in lists, higher weight sink to the bottom."
      }
    },
    "required" => [
      "title",
      "slug",
      "date",
      "draft",
      "body"
    ],
    "additionalProperties" => true
  }

  describe "parse params" do
    test "basic types" do
      params = %{
        "value--title" => "My title",
        "value--slug" => "my-slug",
        "value--date" => "2020-04-02T01:01:00+00:00",
        "value--draft" => "true",
        "value--body" => "<p>More text</p>",
        "value--weight" => "5"
      }

      %{values: values} = BoldTip.fieldset_from_params(params, @base_schema)

      assert %{
               "title" => "My title",
               "slug" => "my-slug",
               "date" => "2020-04-02T01:01:00+00:00",
               "draft" => true,
               "body" => "<p>More text</p>",
               "weight" => 5
             } = values
    end

    test "basic array" do
      params = %{
        "value--categories--0" => "my-category-1",
        "value--categories--1" => "my-category-2"
      }

      %{values: values} = BoldTip.fieldset_from_params(params, @base_schema)

      assert %{
               "categories" => [
                 "my-category-1",
                 "my-category-2"
               ]
             } = values
    end

    test "basic object, no subschema" do
      params = %{
        "value--cascade--custom_field" => "foo",
        "value--cascade--other_customer_field" => "bar"
      }

      %{values: values} = BoldTip.fieldset_from_params(params, @base_schema)

      assert %{
               "cascade" => %{
                 "custom_field" => "foo",
                 "other_customer_field" => "bar"
               }
             } = values
    end

    test "array of objects with object subschema" do
      params = %{
        "value--resources--0--name" => "img.png",
        "value--resources--0--src" => "A:/folder/img.png",
        "value--resources--0--title" => "Image from floppy",
        "value--resources--0--params--custom_field" => "foo",
        "value--resources--0--params--other_field" => "bar",
        "value--resources--1--name" => "other_img.png",
        "value--resources--1--src" => "C:/folder/other_img.png",
        "value--resources--1--params--custom_field" => "baz"
      }

      %{values: values} = BoldTip.fieldset_from_params(params, @base_schema)

      assert %{
               "resources" => [
                 %{
                   "name" => "img.png",
                   "src" => "A:/folder/img.png",
                   "title" => "Image from floppy",
                   "params" => %{
                     "custom_field" => "foo",
                     "other_field" => "bar"
                   }
                 },
                 %{
                   "name" => "other_img.png",
                   "src" => "C:/folder/other_img.png",
                   "params" => %{
                     "custom_field" => "baz"
                   }
                 }
               ]
             } = values
    end

    test "error, array of objects without schema definitions" do
      params = %{
        "value--fresources--0--name" => "img.png",
        "value--fresources--0--src" => "A:/folder/img.png",
        "value--fresources--0--title" => "Image from floppy",
        "value--fresources--0--params--custom_field" => "foo",
        "value--fresources--0--params--other_field" => "bar",
        "value--fresources--1--name" => "other_img.png",
        "value--fresources--1--src" => "C:/folder/other_img.png",
        "value--fresources--1--params--custom_field" => "baz"
      }

      assert_raise RuntimeError, fn ->
        BoldTip.fieldset_from_params(params, @base_schema)
      end
    end
  end

  describe "schema validation" do
    test "required, all present" do
      assert %Fieldset{valid?: true} =
               %{
                 "value--title" => "My title",
                 "value--slug" => "my-slug",
                 "value--date" => "2020-04-02T01:01:00+00:00",
                 "value--draft" => "true",
                 "value--body" => "<p>More text</p>",
                 "value--weight" => "5"
               }
               |> BoldTip.fieldset_from_params(@base_schema)
               |> BoldTip.validate_fields()
    end

    test "required, missing slug" do
      assert %Fieldset{valid?: false, errors: errors} =
               %{
                 "value--title" => "My title",
                 "value--date" => "2020-04-02T01:01:00+00:00",
                 "value--draft" => "true",
                 "value--body" => "<p>More text</p>"
               }
               |> BoldTip.fieldset_from_params(@base_schema)
               |> BoldTip.validate_fields()

      assert %JsonXema.ValidationError{
               message: nil,
               reason: %{required: ["slug"]}
             } = errors
    end

    test "basic array" do
      assert %Fieldset{valid?: true} =
               %{
                 "value--title" => "My title",
                 "value--slug" => "my-slug",
                 "value--date" => "2020-04-02T01:01:00+00:00",
                 "value--draft" => "true",
                 "value--body" => "<p>More text</p>",
                 "value--categories--0" => "my-category-1",
                 "value--categories--1" => "my-category-2"
               }
               |> BoldTip.fieldset_from_params(@base_schema)
               |> BoldTip.validate_fields()
    end

    test "basic object" do
      assert %Fieldset{valid?: true} =
               %{
                 "value--title" => "My title",
                 "value--slug" => "my-slug",
                 "value--date" => "2020-04-02T01:01:00+00:00",
                 "value--draft" => "true",
                 "value--body" => "<p>More text</p>",
                 "value--cascade--custom_field" => "foo",
                 "value--cascade--other_customer_field" => "bar"
               }
               |> BoldTip.fieldset_from_params(@base_schema)
               |> BoldTip.validate_fields()
    end

    test "array of objects with object subschema" do
      assert %Fieldset{valid?: true} =
               %{
                 "value--title" => "My title",
                 "value--slug" => "my-slug",
                 "value--date" => "2020-04-02T01:01:00+00:00",
                 "value--draft" => "true",
                 "value--body" => "<p>More text</p>",
                 "value--resources--0--name" => "img.png",
                 "value--resources--0--src" => "A:/folder/img.png",
                 "value--resources--0--title" => "Image from floppy",
                 "value--resources--0--params--custom_field" => "foo",
                 "value--resources--0--params--other_field" => "bar",
                 "value--resources--1--name" => "other_img.png",
                 "value--resources--1--src" => "C:/folder/other_img.png",
                 "value--resources--1--params--custom_field" => "baz"
               }
               |> BoldTip.fieldset_from_params(@base_schema)
               |> BoldTip.validate_fields()
    end
  end
end
