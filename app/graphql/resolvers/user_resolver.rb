# app/graphql/resolvers/user_resolver.rb
module Resolvers
  class UserResolver < BaseResolver
    type Types::UserType, null: false
    argument :id, ID

    def resolve(id:)
      ::User.find(id)
    end
  end
end
