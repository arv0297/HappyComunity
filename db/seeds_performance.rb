# frozen_string_literal: true

# This seed creates 50 books with 500,000 distributed reviews for performance testing
puts "Starting performance seed..."

# Clean up existing performance test data
puts "Cleaning up existing performance test data..."
Review.where("content LIKE ?", "Performance test review%").delete_all
User.where("email LIKE ?", "perfuser%@example.com").delete_all
Book.where("title LIKE ?", "Performance Test Book%").delete_all
puts "Cleanup complete"

puts "Creating 50 books..."
books = []
50.times do |i|
  books << Book.find_or_create_by!(title: "Performance Test Book #{i}", author: "Author #{i}") do |b|
    b.average_rating = nil
    b.reviews_count = 0
  end
end
puts "Created 50 books"

# Create users in batches
BATCH_SIZE = 1000
TOTAL_USERS = 10_100  # Extra buffer to ensure we can create exactly 500k unique reviews
TOTAL_REVIEWS = 500_000

puts "Creating #{TOTAL_USERS} users in batches of #{BATCH_SIZE}..."

users_data = []
TOTAL_USERS.times do |i|
  users_data << {
    name: "PerfUser",
    last_name: "Test",
    second_last_name: "User",
    email: "perfuser#{i}@example.com",
    dni: i.to_s.rjust(8, '0'),
    active: true,
    banned: false,
    born_date: 30.years.ago
  }

  if (i + 1) % BATCH_SIZE == 0
    User.insert_all(users_data)
    puts "Created #{i + 1} users..."
    users_data = []
  end
end

# Insert remaining users
if users_data.any?
  User.insert_all(users_data)
  puts "Created #{TOTAL_USERS} users..."
end

# Get actual user IDs from the database
puts "Fetching user IDs..."
user_ids = User.where("email LIKE ?", "perfuser%@example.com").pluck(:id)
puts "Found #{user_ids.size} performance test users"

if user_ids.size < TOTAL_USERS
  puts "ERROR: Expected #{TOTAL_USERS} users, but found #{user_ids.size}"
  exit 1
end

puts "Distributing #{TOTAL_REVIEWS} reviews across #{books.size} books..."

# Systematic distribution to guarantee exactly 500,000 reviews
# Each user reviews each book exactly once: 10,000 users × 50 books = 500,000 reviews
reviews_data = []
reviews_created = 0

user_ids.each_with_index do |user_id, user_index|
  books.each_with_index do |book, book_index|
    rating = rand(1..5)

    reviews_data << {
      user_id: user_id,
      book_id: book.id,
      rating: rating,
      content: "Performance test review #{reviews_created}",
      created_at: Time.current,
      updated_at: Time.current
    }

    reviews_created += 1

    # Insert in batches
    if reviews_data.size >= BATCH_SIZE
      Review.insert_all(reviews_data)
      puts "Created #{reviews_created}/#{TOTAL_REVIEWS} reviews..."
      reviews_data = []
    end
  end

  if (user_index + 1) % 1000 == 0
    puts "Processed #{user_index + 1} users..."
  end
end

# Insert remaining reviews
if reviews_data.any?
  Review.insert_all(reviews_data)
  puts "Created #{reviews_created}/#{TOTAL_REVIEWS} reviews..."
end

puts "Successfully created #{reviews_created} reviews"

# Recalculate averages for all books
puts "Recalculating averages for all books..."
books.each_with_index do |book, index|
  book.recalculate_average!
  if (index + 1) % 10 == 0
    puts "Recalculated #{index + 1} books..."
  end
end

puts "Performance test data created successfully!"
puts "Total books: #{books.size}"
puts "Total users: #{TOTAL_USERS}"
puts "Total reviews: #{TOTAL_REVIEWS}"
