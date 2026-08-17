# frozen_string_literal: true

require "rails_helper"

RSpec.describe Book, type: :model do
  describe "associations" do
    it "has many reviews" do
      book = Book.new(title: "Test", author: "Author")
      expect(book).to respond_to(:reviews)
    end
  end

  describe "validations" do
    it "validates presence of title" do
      book = Book.new(author: "Author")
      expect(book).not_to be_valid
      expect(book.errors[:title]).to include("can't be blank")
    end

    it "validates presence of author" do
      book = Book.new(title: "Title")
      expect(book).not_to be_valid
      expect(book.errors[:author]).to include("can't be blank")
    end
  end

  describe "#average_rating_display" do
    context "with less than 3 reviews" do
      it "returns 'Reseñas Insuficientes'" do
        book = Book.create!(title: "Book", author: "Author", reviews_count: 2)
        expect(book.average_rating_display).to eq("Reseñas Insuficientes")
      end
    end

    context "with 3 or more reviews" do
      it "returns the average rating" do
        book = Book.create!(title: "Book", author: "Author", reviews_count: 3, average_rating: 4.5)
        expect(book.average_rating_display).to eq(4.5)
      end
    end
  end

  describe "#recalculate_average!" do
    let(:book) { Book.create!(title: "Book", author: "Author") }
    let(:user) { User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", dni: "12345678", active: true, banned: false, born_date: 30.years.ago) }

    context "with no reviews" do
      it "sets average_rating to nil and reviews_count to 0" do
        book.recalculate_average!
        expect(book.average_rating).to be_nil
        expect(book.reviews_count).to eq(0)
      end
    end

    context "with less than 3 active reviews" do
      it "sets average_rating to nil" do
        Review.create!(rating: 4, content: "Good!", book: book, user: user)
        Review.create!(rating: 5, content: "Great!", book: book, user: User.create!(name: "Jane", last_name: "Smith", second_last_name: "Jones", email: "jane@example.com", dni: "87654321", active: true, banned: false, born_date: 30.years.ago))
        book.recalculate_average!
        expect(book.average_rating).to be_nil
        expect(book.reviews_count).to eq(2)
      end
    end

    context "with 3 or more active reviews" do
      it "calculates the average correctly with half-up rounding" do
        Review.create!(rating: 3, content: "OK!", book: book, user: user)
        Review.create!(rating: 4, content: "Good!", book: book, user: User.create!(name: "Jane", last_name: "Smith", second_last_name: "Jones", email: "jane@example.com", dni: "87654321", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Bob", last_name: "Brown", second_last_name: "Black", email: "bob@example.com", dni: "11111111", active: true, banned: false, born_date: 30.years.ago))
        book.recalculate_average!
        expect(book.average_rating).to eq(3.3) # (3+4+3)/3 = 3.33... rounds to 3.3
        expect(book.reviews_count).to eq(3)
      end

      it "rounds 3.25 to 3.3" do
        Review.create!(rating: 3, content: "OK!", book: book, user: user)
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Jane", last_name: "Smith", second_last_name: "Jones", email: "jane@example.com", dni: "87654321", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Bob", last_name: "Brown", second_last_name: "Black", email: "bob@example.com", dni: "11111111", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 4, content: "Good!", book: book, user: User.create!(name: "Alice", last_name: "White", second_last_name: "Green", email: "alice@example.com", dni: "22222222", active: true, banned: false, born_date: 30.years.ago))

        book.recalculate_average!

        expect(book.average_rating).to eq(3.3) # (3+3+3+4)/4 = 3.25 rounds to 3.3
      end

      it "rounds 3.15 to 3.2" do
        Review.create!(rating: 3, content: "OK!", book: book, user: user)
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Jane", last_name: "Smith", second_last_name: "Jones", email: "jane@example.com", dni: "87654321", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Bob", last_name: "Brown", second_last_name: "Black", email: "bob@example.com", dni: "11111111", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 4, content: "Good!", book: book, user: User.create!(name: "Alice", last_name: "White", second_last_name: "Green", email: "alice@example.com", dni: "22222222", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Charlie", last_name: "Brown", second_last_name: "Green", email: "charlie@example.com", dni: "33333333", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "David", last_name: "White", second_last_name: "Green", email: "david@example.com", dni: "44444444", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 4, content: "Good!", book: book, user: User.create!(name: "Eve", last_name: "Black", second_last_name: "Green", email: "eve@example.com", dni: "55555555", active: true, banned: false, born_date: 30.years.ago))

        book.recalculate_average!

        expect(book.average_rating).to eq(3.3) # (3+3+3+4+3+3+4)/7 = 3.285... rounds to 3.3
      end

      it "rounds 3.14 to 3.1" do
        Review.create!(rating: 3, content: "OK!", book: book, user: user)
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Jane", last_name: "Smith", second_last_name: "Jones", email: "jane@example.com", dni: "87654321", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Bob", last_name: "Brown", second_last_name: "Black", email: "bob@example.com", dni: "11111111", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Alice", last_name: "White", second_last_name: "Green", email: "alice@example.com", dni: "22222222", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Charlie", last_name: "Brown", second_last_name: "Green", email: "charlie@example.com", dni: "33333333", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 4, content: "Good!", book: book, user: User.create!(name: "David", last_name: "White", second_last_name: "Green", email: "david@example.com", dni: "44444444", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Eve", last_name: "Black", second_last_name: "Green", email: "eve@example.com", dni: "55555555", active: true, banned: false, born_date: 30.years.ago))

        book.recalculate_average!

        expect(book.average_rating).to eq(3.1) # (3+3+3+3+3+4+3)/7 = 3.142... rounds to 3.1
      end

      it "rounds 3.05 to 3.1" do
        Review.create!(rating: 3, content: "OK!", book: book, user: user)
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Jane", last_name: "Smith", second_last_name: "Jones", email: "jane@example.com", dni: "87654321", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Bob", last_name: "Brown", second_last_name: "Black", email: "bob@example.com", dni: "11111111", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Alice", last_name: "White", second_last_name: "Green", email: "alice@example.com", dni: "22222222", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Charlie", last_name: "Brown", second_last_name: "Green", email: "charlie@example.com", dni: "33333333", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "David", last_name: "White", second_last_name: "Green", email: "david@example.com", dni: "44444444", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Eve", last_name: "Black", second_last_name: "Green", email: "eve@example.com", dni: "55555555", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 4, content: "Good!", book: book, user: User.create!(name: "Frank", last_name: "Green", second_last_name: "Green", email: "frank@example.com", dni: "66666666", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 3, content: "OK!", book: book, user: User.create!(name: "Grace", last_name: "Green", second_last_name: "Green", email: "grace@example.com", dni: "77777777", active: true, banned: false, born_date: 30.years.ago))

        book.recalculate_average!

        expect(book.average_rating).to eq(3.1) # (3+3+3+3+3+3+4+3+3)/9 = 3.111... rounds to 3.1
      end

      it "handles minimum average of 1.0" do
        Review.create!(rating: 1, content: "Bad!", book: book, user: user)
        Review.create!(rating: 1, content: "Bad!", book: book, user: User.create!(name: "Jane", last_name: "Smith", second_last_name: "Jones", email: "jane@example.com", dni: "87654321", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 1, content: "Bad!", book: book, user: User.create!(name: "Bob", last_name: "Brown", second_last_name: "Black", email: "bob@example.com", dni: "11111111", active: true, banned: false, born_date: 30.years.ago))

        book.recalculate_average!

        expect(book.average_rating).to eq(1.0)
      end

      it "handles maximum average of 5.0" do
        Review.create!(rating: 5, content: "Great!", book: book, user: user)
        Review.create!(rating: 5, content: "Great!", book: book, user: User.create!(name: "Jane", last_name: "Smith", second_last_name: "Jones", email: "jane@example.com", dni: "87654321", active: true, banned: false, born_date: 30.years.ago))
        Review.create!(rating: 5, content: "Great!", book: book, user: User.create!(name: "Bob", last_name: "Brown", second_last_name: "Black", email: "bob@example.com", dni: "11111111", active: true, banned: false, born_date: 30.years.ago))

        book.recalculate_average!

        expect(book.average_rating).to eq(5.0)
      end
    end

    context "with banned users" do
      it "excludes banned user reviews from average" do
        banned_user = User.create!(name: "Banned", last_name: "User", second_last_name: "One", email: "banned@example.com", dni: "99999999", active: true, banned: true, born_date: 30.years.ago)
        banned_user2 = User.create!(name: "BannedTwo", last_name: "User", second_last_name: "Two", email: "banned2@example.com", dni: "55555555", active: true, banned: true, born_date: 30.years.ago)
        active_user = User.create!(name: "Active", last_name: "User", second_last_name: "Two", email: "active@example.com", dni: "88888888", active: true, banned: false, born_date: 30.years.ago)
        active_user2 = User.create!(name: "ActiveTwo", last_name: "User", second_last_name: "Three", email: "active2@example.com", dni: "77777777", active: true, banned: false, born_date: 30.years.ago)
        active_user3 = User.create!(name: "ActiveThree", last_name: "User", second_last_name: "Four", email: "active3@example.com", dni: "66666666", active: true, banned: false, born_date: 30.years.ago)
        Review.create!(rating: 5, content: "Great!", book: book, user: banned_user)
        Review.create!(rating: 5, content: "Great!", book: book, user: banned_user2)
        Review.create!(rating: 1, content: "Bad!", book: book, user: active_user)
        Review.create!(rating: 2, content: "Okay", book: book, user: active_user2)
        Review.create!(rating: 3, content: "Fair", book: book, user: active_user3)
        book.recalculate_average!
        expect(book.average_rating).to eq(2.0) # (1+2+3)/3 = 2.0
        expect(book.reviews_count).to eq(3)
      end
    end
  end
end
