# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviews API", type: :request do
  describe "GraphQL mutations" do
    let(:book) { Book.create!(title: "Test Book", author: "Test Author") }
    let(:user) { User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", encrypted_password: 'testing_pass', dni: "12345678", active: true, banned: false, born_date: 30.years.ago) }

    before do
      # Mock the user context for mutations
      allow(User).to receive(:first).and_return(user)
    end

    describe "createReview" do
      it "creates a new review" do
        query = <<~GRAPHQL
          mutation {
            createReview(input: { bookId: "#{book.id}", email: "#{user.email}", password: "#{user.encrypted_password}", rating: 5, content: "Great book!" }) {
              review {
                id
                rating
                content
              }
              errors
            }
          }
        GRAPHQL

        post "/graphql", params: { query: query }
        json = JSON.parse(response.body)
        expect(json["data"]["createReview"]["review"]["rating"]).to eq(5)
        expect(json["data"]["createReview"]["review"]["content"]).to eq("Great book!")
        expect(json["data"]["createReview"]["errors"]).to be_empty
      end

      it "prevents duplicate reviews from the same user" do
        Review.create!(rating: 4, content: "Good", book: book, user: user)

        query = <<~GRAPHQL
          mutation {
            createReview(input: { bookId: "#{book.id}", email: "#{user.email}", password: "#{user.encrypted_password}", rating: 5 }) {
              review {
                id
              }
              errors
            }
          }
        GRAPHQL

        post "/graphql", params: { query: query }
        json = JSON.parse(response.body)
        expect(json["data"]["createReview"]["review"]).to be_nil
        expect(json["data"]["createReview"]["errors"]).to include(/User has already been taken/)
      end
    end

    describe "updateReview" do
      it "updates an existing review" do
        review = Review.create!(rating: 3, content: "Okay", book: book, user: user)

        query = <<~GRAPHQL
          mutation {
            updateReview(input: { id: "#{review.id}", email: "#{user.email}", password: "#{user.encrypted_password}", rating: 5, content: "Amazing!" }) {
              review {
                id
                rating
                content
              }
              errors
            }
          }
        GRAPHQL

        post "/graphql", params: { query: query }
        json = JSON.parse(response.body)
        expect(json["data"]["updateReview"]["review"]["rating"]).to eq(5)
        expect(json["data"]["updateReview"]["review"]["content"]).to eq("Amazing!")
      end
    end

    describe "deleteReview" do
      it "deletes a review" do
        review = Review.create!(rating: 5, content: "Great", book: book, user: user)

        query = <<~GRAPHQL
          mutation {
            deleteReview(input: { id: "#{review.id}", email: "#{user.email}", password: "#{user.encrypted_password}" }) {
              success
              errors
            }
          }
        GRAPHQL

        post "/graphql", params: { query: query }
        json = JSON.parse(response.body)
        expect(json["data"]["deleteReview"]["success"]).to be true
        expect { review.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GraphQL queries" do
    let(:book) { Book.create!(title: "Test Book", author: "Test Author") }
    let(:user) { User.create!(name: "John", last_name: "Doe", second_last_name: "Smith", email: "john@example.com", encrypted_password: 'testing_pass', dni: "12345678", active: true, banned: false, born_date: 30.years.ago) }
    let(:banned_user) { User.create!(name: "Banned", last_name: "User", second_last_name: "One", email: "banned@example.com", encrypted_password: 'testing_pass', dni: "99999999", active: true, banned: true, born_date: 30.years.ago) }

    before do
      Review.create!(rating: 5, content: "Great!", book: book, user: user)
      Review.create!(rating: 1, content: "Bad!", book: book, user: banned_user)
    end

    describe "top_books" do
      it "returns a list of top_books with their averages" do
        query = <<~GRAPHQL
          query {
            topBooks(limit: 5) {
              id
              title
              author
              averageRating
              reviewsCount
              averageRatingDisplay
            }
          }
        GRAPHQL

        post "/graphql", params: { query: query }
        json = JSON.parse(response.body)
        top_books = json["data"]["topBooks"]
        expect(top_books).to be_an(Array)
        expect(top_books.first["title"]).to eq(book.title)
      end
    end

    describe "reviews" do
      it "returns only non-banned user reviews" do
        query = <<~GRAPHQL
          query {
            reviews(bookId: "#{book.id}") {
              id
              rating
              content
              user {
                id
                banned
              }
            }
          }
        GRAPHQL

        post "/graphql", params: { query: query }
        json = JSON.parse(response.body)
        reviews = json["data"]["reviews"]
        expect(reviews.length).to eq(1)
        expect(reviews.first["user"]["banned"]).to be false
      end
    end
  end
end
