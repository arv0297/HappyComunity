# frozen_string_literal: true

module Mutations
  class DeleteReview < BaseMutation
    argument :id, ID, required: true
    argument :email, String, required: false
    argument :password, String, required: false

    field :success, Boolean, null: false
    field :errors, [String], null: false

    def resolve(id:, email: nil, password: nil)
      is_authenticated = false
      is_authenticated = true if context[:authenticated]

      review = Review.find(id)

      if !is_authenticated && email.present? && password.present?
        user = User.find_by(email: email.to_s.downcase.strip)

        return { review: nil, errors: ["User doesn´t exist"] } unless user.present?
        return { success: false, errors: ["Invalid email or password"] } unless user.encrypted_password == password
        return { success: false, errors: ["User is banned"] } if user.banned

        is_authenticated = review.user_id == user.id
      end

      return { success: false, errors: ["Not authorized"] } unless is_authenticated

      if review.destroy
        { success: true, errors: [] }
      else
        { success: false, errors: review.errors.full_messages }
      end
    rescue ActiveRecord::RecordNotFound
      { success: false, errors: ["Review not found"] }
    end
  end
end