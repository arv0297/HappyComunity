class HomePagesController < ApplicationController
  def index
    @user = User.last
  end

  def home
    @total_books = Book.count
    @total_reviews = Book.sum(:reviews_count)
    @top_rated_books = Book.where.not(average_rating: nil).order(average_rating: :desc).limit(5)
    @recent_books = Book.order(created_at: :desc).limit(5)
  end
end
