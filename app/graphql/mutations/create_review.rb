# frozen_string_literal: true

module Mutations
  class CreateReview < BaseMutation
    argument :book_id, ID, required: true
    argument :email, String, required: true
    argument :password, String, required: true
    argument :rating, Integer, required: true
    argument :content, String, required: false

    field :review, Types::ReviewType, null: true
    field :errors, [ String ], null: false

    def resolve(book_id:, email:, password:, rating:, content: nil)
      is_authenticated = false
      is_authenticated = true if context[:authenticated]

      if email.present? && password.present?
        user = User.find_by(email: email.to_s.downcase.strip)
        return { review: nil, errors: [ "User doesn´t exist" ] } unless user.present?
        return { review: nil, errors: [ "Invalid email or password" ] } unless user.encrypted_password == password
        return { review: nil, errors: [ "User is banned" ] } if user.banned

        is_authenticated = true
      end

      return { review: nil, errors: [ "Not authenticated" ] } unless is_authenticated

      book = Book.find(book_id)

      review = Review.new(
        user: user,
        book: book,
        rating: rating,
        content: content
      )

      if review.save
        { review: review, errors: [] }
      else
        { review: nil, errors: review.errors.full_messages }
      end
    rescue ActiveRecord::RecordNotFound
      { review: nil, errors: [ "Book not found" ] }
    end
  end
end
