# frozen_string_literal: true

module Resolvers
  class ReviewsResolver < Resolvers::BaseResolver
    type [ Types::ReviewType ], null: false
    argument :book_id, ID, required: true

    def resolve(book_id:)
      Review.joins(:user)
            .where(book_id: book_id)
            .where(users: { banned: false })
    end
  end
end
