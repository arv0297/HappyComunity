# frozen_string_literal: true

# Performance measurement script for the home page query
# Run with: rails runner scripts/measure_performance.rb

require 'benchmark'

puts "Performance Measurement for Home Page Query"
puts "=" * 50

# Ensure we have data
book_count = Book.count
if book_count < 50
  puts "Creating 50 books for testing..."
  50.times do |i|
    Book.create!(
      title: "Book #{i}",
      author: "Author #{i}",
      average_rating: nil,
      reviews_count: 0
    )
  end
end

# Measure the home page query (50 books with their averages)
puts "\nMeasuring: Query 50 books with their cached averages"
time = Benchmark.realtime do
  books = Book.limit(50).select(:id, :title, :author, :average_rating, :reviews_count)
  books.each do |book|
    book.average_rating_display
  end
end

puts "Time: #{(time * 1000).round(2)}ms"
puts "Books retrieved: #{Book.limit(50).count}"

# Compare with naive approach (calculating average on the fly)
puts "\nMeasuring: Naive approach (calculating average from reviews)"
time_naive = Benchmark.realtime do
  books = Book.limit(50)
  books.each do |book|
    active_reviews = book.reviews.joins(:user).where(users: { banned: false })
    if active_reviews.count >= 3
      avg = active_reviews.average(:rating)
      avg.round(1)
    else
      "Reseñas Insuficientes"
    end
  end
end

puts "Time: #{(time_naive * 1000).round(2)}ms"
puts "Speedup: #{(time_naive / time).round(2)}x faster with cached approach"

# Test with a book that has many reviews
popular_book = Book.order(reviews_count: :desc).first
if popular_book && popular_book.reviews_count > 0
  puts "\nPopular book: #{popular_book.title}"
  puts "Total reviews: #{popular_book.reviews_count}"
  puts "Cached average: #{popular_book.average_rating_display}"
  puts "\nMeasuring: Single book average retrieval (cached)"
  time_cached = Benchmark.realtime do
    popular_book.average_rating_display
  end
  puts "Time: #{(time_cached * 1000).round(2)}ms"
  puts "\nMeasuring: Single book average calculation (from reviews)"
  time_calc = Benchmark.realtime do
    active_reviews = popular_book.reviews.joins(:user).where(users: { banned: false })
    if active_reviews.count >= 3
      active_reviews.average(:rating).round(1)
    else
      "Reseñas Insuficientes"
    end
  end
  puts "Time: #{(time_calc * 1000).round(2)}ms"
  puts "Speedup: #{(time_calc / time_cached).round(2)}x faster with cached approach"
end

puts "\n" + "=" * 50
puts "Conclusion: The cached approach provides O(1) performance"
puts "regardless of the number of reviews per book."
