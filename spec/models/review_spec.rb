# frozen_string_literal: true

require "rails_helper"

RSpec.describe Review, type: :model do
  describe "associations" do
    it "belongs to user" do
      review = Review.new(rating: 5, content: "Test")
      expect(review).to respond_to(:user)
    end

    it "belongs to book" do
      review = Review.new(rating: 5, content: "Test")
      expect(review).to respond_to(:book)
    end
  end

  describe "validations" do
    it "validates presence of rating" do
      review = Review.new(content: "Test")
      expect(review).not_to be_valid
      expect(review.errors[:rating]).to include("can't be blank")
    end

    it "validates inclusion of rating in 1..5" do
      review = Review.new(rating: 6, content: "Test")
      expect(review).not_to be_valid
      expect(review.errors[:rating]).to include("is not included in the list")
    end

    it "validates length of content is at most 1000" do
      review = Review.new(rating: 5, content: "a" * 1001)
      expect(review).not_to be_valid
      expect(review.errors[:content]).to include("is too long (maximum is 1000 characters)")
    end

    it "validates uniqueness of user_id scoped to book_id" do
      book = Book.create!(title: "Book", author: "Author")
      user = User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: false, born_date: 30.years.ago)
      Review.create!(rating: 5, content: "Test", book: book, user: user)
      duplicate = Review.new(rating: 4, content: "Test2", book: book, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end
  end

  describe "callbacks" do
    let(:book) { Book.create!(title: "Book", author: "Author") }
    let(:user) { User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: false, born_date: 30.years.ago) }

    context "after create" do
      it "updates the book average" do
        expect(book).to receive(:recalculate_average!)
        Review.create!(rating: 5, content: "Great!", book: book, user: user)
      end
    end

    context "after update" do
      it "updates the book average when rating changes" do
        review = Review.create!(rating: 3, content: "OK!", book: book, user: user)
        expect(book).to receive(:recalculate_average!)
        review.update(rating: 5)
      end
    end

    context "after destroy" do
      it "updates the book average" do
        review = Review.create!(rating: 5, content: "Great!", book: book, user: user)
        expect(book).to receive(:recalculate_average!)
        review.destroy
      end
    end
  end

  describe "concurrency safety" do
    let(:book) { Book.create!(title: "Book", author: "Author") }
    let(:user) { User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: false, born_date: 30.years.ago) }

    it "uses database locking when updating book average" do
      review = Review.create!(rating: 5, content: "Great!", book: book, user: user)

      allow(book).to receive(:with_lock).and_yield
      allow(book).to receive(:reload)
      expect(book).to receive(:recalculate_average!)

      review.update(rating: 4)
    end

    it "handles 200 concurrent reviews correctly" do
      threads = []
      errors = []
      mutex = Mutex.new

      # Create 200 different users
      users = 200.times.map do |i|
        User.create!(
          name: "User",
          last_name: "Test",
          second_last_name: "Last",
          email: "user#{i}@example.com",
          dni: i.to_s.rjust(8, '0'),
          active: true,
          banned: false,
          born_date: 30.years.ago
        )
      end

      # Create 200 threads that each try to create a review
      200.times do |i|
        threads << Thread.new do
          begin
            Review.create!(
              rating: rand(1..5),
              content: "Review #{i}",
              book: book,
              user: users[i]
            )
          rescue ActiveRecord::RecordInvalid => e
            mutex.synchronize { errors << e.message }
          end
        end
      end

      # Wait for all threads to complete
      threads.each(&:join)

      # Verify no errors occurred
      expect(errors).to be_empty

      # Reload the book to get the final state
      book.reload

      # Verify the correct number of reviews
      expect(book.reviews.count).to eq(200)

      # Verify the average is correct
      expected_sum = users.each_with_index.sum { |_, i| book.reviews[i].rating }
      expected_average = (expected_sum.to_f / 200).round(1)
      expect(book.average_rating).to eq(expected_average)
      expect(book.reviews_count).to eq(200)
    end

    it "maintains uniqueness constraint under concurrency" do
      threads = []
      errors = []
      mutex = Mutex.new
      successful_reviews = 0

      # Try to create 200 reviews for the same user and book
      200.times do
        threads << Thread.new do
          begin
            Review.create!(
              rating: rand(1..5),
              content: "Concurrent review",
              book: book,
              user: user
            )
            mutex.synchronize { successful_reviews += 1 }
          rescue ActiveRecord::RecordInvalid => e
            mutex.synchronize { errors << e.message }
          end
        end
      end

      threads.each(&:join)

      # Only one review should succeed due to uniqueness constraint
      expect(successful_reviews).to eq(1)
      expect(book.reviews.where(user: user).count).to eq(1)
    end
  end
end
