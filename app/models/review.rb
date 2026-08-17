# frozen_string_literal: true

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :content, length: { maximum: 1000 }, allow_blank: true
  validates :user_id, uniqueness: { scope: :book_id }

  after_create :update_book_average
  after_update :update_book_average
  after_destroy :update_book_average

  private

  def update_book_average
    book.with_lock do
      book.recalculate_average!
    end
  end
end
