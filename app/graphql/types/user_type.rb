# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :name, String
    field :last_name, String
    field :second_last_name, String
    field :dni, String, null: false
    field :born_date, GraphQL::Types::ISO8601Date
    field :active, Boolean, null: false
    field :banned, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
