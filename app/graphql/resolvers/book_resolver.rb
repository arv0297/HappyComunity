# frozen_string_literal: true

module Resolvers
  class BookResolver < Resolvers::BaseResolver
    type Types::BookType, null: true
    argument :id, ID, required: true

    def resolve(id:)
      Book.find_by(id: id)
    end
  end
end
