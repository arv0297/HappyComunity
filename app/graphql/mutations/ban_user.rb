# frozen_string_literal: true

module Mutations
  class BanUser < BaseMutation
    argument :user_id, ID, required: true

    field :user, Types::UserType, null: true
    field :errors, [ String ], null: false

    def resolve(user_id:)
      is_authenticated = true if context[:authenticated]

      return { user: nil, errors: [ "Not authorized" ] } unless is_authenticated

      user = User.find(user_id)
      if user.ban!
        { user: user, errors: [] }
      else
        { user: nil, errors: user.errors.full_messages }
      end
    rescue ActiveRecord::RecordNotFound
      { user: nil, errors: [ "User not found" ] }
    end
  end
end
