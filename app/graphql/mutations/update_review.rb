# frozen_string_literal: true

module Mutations
  class UpdateReview < BaseMutation
    argument :id, ID, required: true
    argument :email, String, required: false
    argument :password, String, required: false
    argument :rating, Integer, required: false
    argument :content, String, required: false

    field :review, Types::ReviewType, null: true
    field :errors, [ String ], null: false

    def resolve(id:, email: nil, password: nil, rating: nil, content: nil)
      is_authenticated = false
      is_authenticated = true if context[:authenticated]

      review = Review.find(id)

      if !is_authenticated && email.present? && password.present?
        user = User.find_by(email: email.to_s.downcase.strip)

        return { review: nil, errors: [ "User doesn´t exist" ] } unless user.present?
        return { review: nil, errors: [ "Invalid email or password" ] } unless user.encrypted_password == password
        return { review: nil, errors: [ "User is banned" ] } if user.banned

        is_authenticated = review.user_id == user.id
      end

      return { review: nil, errors: [ "Not authorized" ] } unless is_authenticated

      attributes = {}
      attributes[:rating] = rating unless rating.nil?
      attributes[:content] = content unless content.nil?

      if review.update(attributes)
        { review: review, errors: [] }
      else
        { review: nil, errors: review.errors.full_messages }
      end
    rescue ActiveRecord::RecordNotFound
      { review: nil, errors: [ "Review not found" ] }
    end
  end
end
