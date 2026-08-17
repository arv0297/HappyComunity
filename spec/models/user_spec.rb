require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it "has many reviews" do
      user = User.new(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: false, born_date: 30.years.ago)
      expect(user).to respond_to(:reviews)
    end
  end

  describe "validations" do
    it "validates inclusion of banned in [true, false]" do
      user = User.new(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: nil, born_date: 30.years.ago)
      expect(user).not_to be_valid
      expect(user.errors[:banned]).to include("is not included in the list")
    end
  end

  describe "Show complete name" do
    it "returns the complete name" do
      user = User.new(
        name: "John",
        last_name: "Doe",
        second_last_name: "Smith"
      )

      expect(user.full_name).to eq("John Doe Smith")
    end
  end

  describe "#ban!" do
    it "sets banned to true" do
      user = User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: false, born_date: 30.years.ago)
      user.ban!
      expect(user.reload.banned).to be true
    end
  end

  describe "#unban!" do
    it "sets banned to false" do
      user = User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: true, born_date: 30.years.ago)
      user.unban!
      expect(user.reload.banned).to be false
    end
  end

  describe "callbacks" do
    let(:user) { User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: false, born_date: 30.years.ago) }
    let(:book1) { Book.create!(title: "Book 1", author: "Author 1") }
    let(:book2) { Book.create!(title: "Book 2", author: "Author 2") }

    before do
      Review.create!(rating: 5, content: "Great!", book: book1, user: user)
      Review.create!(rating: 4, content: "Good!", book: book2, user: user)
    end

    context "when user is banned" do
      it "updates averages for all books the user reviewed" do
        user.ban!

        expect(book1.reload.average_rating).to be_nil
        expect(book2.reload.average_rating).to be_nil
      end
    end

    context "when user is unbanned" do
      it "updates averages for all books the user reviewed" do
        user.update(banned: true)

        user.unban!

        expect(book1.reload.average_rating).to be_nil
        expect(book2.reload.average_rating).to be_nil
      end
    end

    context "when banned status does not change" do
      it "does not update book averages" do
        expect(book1).not_to receive(:recalculate_average!)
        expect(book2).not_to receive(:recalculate_average!)

        user.update(name: "New Name")
      end
    end
  end

  describe "concurrency safety" do
    let(:user) { User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: false, born_date: 30.years.ago) }
    let(:book) { Book.create!(title: "Book", author: "Author") }

    before do
      Review.create!(rating: 5, content: "Great!", book: book, user: user)
    end

    it "uses database locking when updating book averages" do
      allow_any_instance_of(Book).to receive(:with_lock).and_yield
      allow_any_instance_of(Book).to receive(:reload)
      expect_any_instance_of(Book).to receive(:recalculate_average!)

      user.ban!
    end
  end

  describe "massive retroactive ban" do
    it "updates averages for thousands of reviews across many books" do
      books = []
      fake_users = []
      num_books = 100
      fake_users_per_book = 10
      # Fixed, deterministic ratings for the "legitimate" reviews on each book.
      # Sum = 5, so with 10 fake 5-star reviews:
      #   before ban: (10*5 + 5) / 15 = 3.67  (clearly < 4.0)
      #   after ban:   5 / 5           = 1.0   (clearly < 4.0)
      # This removes the flakiness that came from using rand(1..3), which
      # could occasionally sum to exactly 10 and land the average exactly
      # on 4.0, failing a strict `> 4.0` comparison.
      legit_ratings = [ 1, 1, 1, 1, 1 ]

      # Create 100 books
      num_books.times do |i|
        book = Book.create!(title: "Book #{i}", author: "Author #{i}")
        books << book

        # Create 10 fake users per book who each review the book once
        fake_users_per_book.times do |j|
          fake_user = User.create!(
            name: "Fake",
            last_name: "User",
            second_last_name: "Test",
            email: "fake#{i}_#{j}@example.com",
            dni: "9#{i}#{j}".rjust(8, '0'),
            active: true,
            banned: false,
            born_date: 30.years.ago
          )
          fake_users << fake_user
          Review.create!(rating: 5, content: "Fake review!", book: book, user: fake_user)
        end

        # Add some legitimate reviews from other users to establish averages
        legit_ratings.each_with_index do |rating, j|
          other_user = User.create!(
            name: "Legit",
            last_name: "User",
            second_last_name: "Test",
            email: "legit#{i}_#{j}@example.com",
            dni: "#{i}#{j}".rjust(8, '0'),
            active: true,
            banned: false,
            born_date: 30.years.ago
          )
          Review.create!(rating: rating, content: "Real review", book: book, user: other_user)
        end

        # Recalculate to establish the initial average (including fake reviews)
        book.recalculate_average!
      end

      # Verify initial state - all books should have high averages due to fake 5-star reviews
      books.each do |book|
        book.reload
        expect(book.reviews_count).to eq(15) # 10 fake + 5 legit
        expect(book.average_rating).to be > 3.5 # Should be high due to fake 5-star reviews
      end

      # Ban all fake users
      fake_users.each { |user| user.ban! }

      # Verify all books updated correctly - averages should now be lower
      books.each do |book|
        book.reload
        expect(book.reviews_count).to eq(5) # Only 5 legit reviews remain
        expect(book.average_rating).to be < 2.0 # Should be lower without fake reviews
      end

      # Unban all fake users
      fake_users.each { |user| user.unban! }

      # Verify averages go back up
      books.each do |book|
        book.reload
        expect(book.reviews_count).to eq(15) # All reviews count again
        expect(book.average_rating).to be > 3.5 # Back to high
      end
    end

    it "handles user with no reviews gracefully" do
      user_with_no_reviews = User.create!(
        name: "Empty",
        last_name: "User",
        second_last_name: "Test",
        email: "empty@example.com",
        dni: "88888888",
        active: true,
        banned: false,
        born_date: 30.years.ago
      )

      # Should not raise any errors
      expect { user_with_no_reviews.ban! }.not_to raise_error
      expect { user_with_no_reviews.unban! }.not_to raise_error
    end
  end
end
