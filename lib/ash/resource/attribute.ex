defmodule Ash.Resource.Attribute do
  @moduledoc "Represents an attribute on a resource"

  defstruct [
    :name,
    :type,
    :allow_nil?,
    :generated?,
    :primary_key?,
    :private?,
    :writable?,
    :always_select?,
    :default,
    :update_default,
    :description,
    :source,
    match_other_defaults?: false,
    sensitive?: false,
    filterable?: true,
    constraints: []
  ]

  defmodule Helpers do
    @moduledoc "Helpers for building attributes"

    defmacro timestamps(opts \\ []) do
      quote do
        create_timestamp :inserted_at, unquote(opts)
        update_timestamp :updated_at, unquote(opts)
      end
    end
  end

  @type t :: %__MODULE__{
          name: atom(),
          constraints: Keyword.t(),
          type: Ash.Type.t(),
          primary_key?: boolean(),
          private?: boolean(),
          default: nil | term | (() -> term),
          update_default: nil | term | (() -> term) | (Ash.Resource.record() -> term),
          sensitive?: boolean(),
          writable?: boolean()
        }

  alias Spark.OptionsHelpers

  @schema [
    name: [
      type: :atom,
      doc: "The name of the attribute.",
      links: []
    ],
    type: [
      type: Ash.OptionsHelpers.ash_type(),
      doc: "The type of the attribute.",
      links: [
        modules: ["ash:module:Ash.Type"]
      ]
    ],
    constraints: [
      type: :keyword_list,
      doc:
        "Constraints to provide to the type when casting the value. See the type's documentation for more information.",
      links: [
        modules: ["ash:module:Ash.Type"]
      ]
    ],
    description: [
      type: :string,
      doc: "An optional description for the attribute.",
      links: []
    ],
    sensitive?: [
      type: :boolean,
      default: false,
      doc: "Whether or not the attribute value contains sensitive information, like PII.",
      links: [
        guides: ["ash:guide:Security"]
      ]
    ],
    source: [
      type: :atom,
      doc: """
      If the field should be mapped to a different name in the data layer. Support varies by data layer.
      """,
      links: []
    ],
    always_select?: [
      type: :boolean,
      default: false,
      doc: """
      Whether or not to ensure this attribute is always selected when reading from the database.
      """,
      links: []
    ],
    primary_key?: [
      type: :boolean,
      default: false,
      doc: """
      Whether or not the attribute is part of the primary key (one or more fields that uniquely identify a resource)."
      If primary_key? is true, allow_nil? must be false.
      """,
      links: []
    ],
    allow_nil?: [
      type: :boolean,
      default: true,
      doc: "Whether or not the attribute can be set to nil.",
      links: []
    ],
    generated?: [
      type: :boolean,
      default: false,
      doc: "Whether or not the value may be generated by the data layer.",
      links: [
        guides: ["ash:guide:Actions"]
      ]
    ],
    writable?: [
      type: :boolean,
      default: true,
      doc: "Whether or not the value can be written to.",
      links: []
    ],
    private?: [
      type: :boolean,
      default: false,
      doc:
        "Whether or not the attribute can be provided as input, or will be shown when extensions work with the resource (i.e won't appear in a web api).",
      links: [
        guides: ["ash:guide:Security"]
      ]
    ],
    default: [
      type: {:or, [{:mfa_or_fun, 0}, :literal]},
      doc: "A value to be set on all creates, unless a value is being provided already.",
      links: [
        guides: ["ash:guide:Actions"]
      ]
    ],
    update_default: [
      type: {:or, [{:mfa_or_fun, 0}, :literal]},
      doc: "A value to be set on all updates, unless a value is being provided already.",
      links: [
        guides: ["ash:guide:Actions"]
      ]
    ],
    filterable?: [
      type: {:or, [:boolean, {:in, [:simple_equality]}]},
      default: true,
      doc: "Whether or not the attribute can be referenced in filters.",
      links: []
    ],
    match_other_defaults?: [
      type: :boolean,
      default: false,
      doc: """
      Ensures that other attributes that use the same "lazy" default (a function or an mfa), use the same default value.
      Has no effect unless `default` is a zero argument function.
      For example, create and update timestamps use this option, and have the same lazy function `&DateTime.utc_now/0`, so they
      get the same value, instead of having slightly different timestamps.
      """,
      links: [
        guides: ["ash:guide:Actions"]
      ]
    ]
  ]

  @create_timestamp_schema @schema
                           |> OptionsHelpers.set_default!(:writable?, false)
                           |> OptionsHelpers.set_default!(:private?, true)
                           |> OptionsHelpers.set_default!(:default, &DateTime.utc_now/0)
                           |> OptionsHelpers.set_default!(:match_other_defaults?, true)
                           |> OptionsHelpers.set_default!(:type, Ash.Type.UtcDatetimeUsec)
                           |> OptionsHelpers.set_default!(:allow_nil?, false)

  @update_timestamp_schema @schema
                           |> OptionsHelpers.set_default!(:writable?, false)
                           |> OptionsHelpers.set_default!(:private?, true)
                           |> OptionsHelpers.set_default!(:match_other_defaults?, true)
                           |> OptionsHelpers.set_default!(:default, &DateTime.utc_now/0)
                           |> OptionsHelpers.set_default!(
                             :update_default,
                             &DateTime.utc_now/0
                           )
                           |> OptionsHelpers.set_default!(:type, Ash.Type.UtcDatetimeUsec)
                           |> OptionsHelpers.set_default!(:allow_nil?, false)

  @uuid_primary_key_schema @schema
                           |> OptionsHelpers.set_default!(:writable?, false)
                           |> OptionsHelpers.set_default!(:default, &Ash.UUID.generate/0)
                           |> OptionsHelpers.set_default!(:primary_key?, true)
                           |> OptionsHelpers.set_default!(:type, :uuid)
                           |> Keyword.delete(:allow_nil?)

  @integer_primary_key_schema @schema
                              |> OptionsHelpers.set_default!(:writable?, false)
                              |> OptionsHelpers.set_default!(:primary_key?, true)
                              |> OptionsHelpers.set_default!(:generated?, true)
                              |> OptionsHelpers.set_default!(:type, :integer)
                              |> Keyword.delete(:allow_nil?)

  @doc false
  def attribute_schema, do: @schema
  def create_timestamp_schema, do: @create_timestamp_schema
  def update_timestamp_schema, do: @update_timestamp_schema
  def uuid_primary_key_schema, do: @uuid_primary_key_schema
  def integer_primary_key_schema, do: @integer_primary_key_schema
end
