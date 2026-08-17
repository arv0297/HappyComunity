# frozen_string_literal: true

class Book < ApplicationRecord
  has_many :reviews, dependent: :destroy

  validates :title, presence: true
  validates :author, presence: true

  MIN_REVIEWS_FOR_AVERAGE = 3

  def average_rating_display
    return "Reseñas Insuficientes" if reviews_count < MIN_REVIEWS_FOR_AVERAGE
    average_rating
  end

  def recalculate_average!
    active_reviews = reviews.joins(:user).where(users: { banned: false })

    count = active_reviews.count
    average = active_reviews.average(:rating)

    update(
      average_rating: count >= MIN_REVIEWS_FOR_AVERAGE ? average.round(1) : nil,
      reviews_count: count
    )
  end
end
