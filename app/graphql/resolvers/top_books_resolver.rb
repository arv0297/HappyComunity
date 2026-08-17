# frozen_string_literal: true

module Resolvers
  class TopBooksResolver < Resolvers::BaseResolver
    type [ Types::BookType ], null: false
    argument :limit, Integer, required: false, default_value: 10

    def resolve(limit:)
      ::Book.order(average_rating: :desc)
            .limit(limit)
    end
  end
end
