# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    description "The query root of this schema"

    field :user, resolver: Resolvers::UserResolver
    field :top_books, resolver: Resolvers::TopBooksResolver
    field :book, resolver: Resolvers::BookResolver
    field :reviews, resolver: Resolvers::ReviewsResolver
  end
end
