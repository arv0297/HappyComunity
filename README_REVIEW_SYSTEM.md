# Book Review System - Bibliotk

A robust book review system with cached average calculations, user banning support, and concurrency safety.

## Features

- **Review Management**: Users can create, edit, and delete reviews with ratings (1-5 stars) and optional text (max 1000 chars)
- **Average Calculation**: Cached book averages with half-up rounding (3.25 → 3.3)
- **Minimum Reviews Threshold**: Books with < 3 reviews show "Reseñas Insuficientes"
- **User Banning**: Ban/unban users with automatic average recalculation for all their reviewed books
- **Concurrency Safety**: Database locking ensures correct averages under high load (200+ simultaneous reviews)
- **GraphQL API**: Full GraphQL API for queries and mutations

## Setup

### Prerequisites
- Docker
- Docker Compose

### Running the application

1. **Start the containers:**
   ```bash
   docker compose up -d
   ```

2. **Run migrations:**
   ```bash
   docker compose exec web rails db:migrate
   ```

3. **Access GraphQL Playground:**
   Navigate to `http://localhost:3000/graphiql`

### Running tests

```bash
docker compose exec web bundle exec rspec
```

### Running specific test suites

```bash
# Model tests
docker compose exec web bundle exec rspec spec/models

# Request tests
docker compose exec web bundle exec rspec spec/requests
```

## API Usage

### GraphQL Queries

**List books with averages:**
```graphql
query {
  books(limit: 50) {
    id
    title
    author
    averageRating
    reviewsCount
    averageRatingDisplay
  }
}
```

**Get book details:**
```graphql
query {
  book(id: "1") {
    id
    title
    author
    averageRating
    reviewsCount
  }
}
```

**Get reviews for a book (non-banned users only):**
```graphql
query {
  reviews(bookId: "1") {
    id
    rating
    content
    user {
      id
      name
      banned
    }
  }
}
```

### GraphQL Mutations

**Create a review:**
```graphql
mutation {
  createReview(input: { bookId: "1", rating: 5, content: "Great book!" }) {
    review {
      id
      rating
      content
    }
    errors
  }
}
```

**Update a review:**
```graphql
mutation {
  updateReview(input: { id: "1", rating: 4, content: "Updated review" }) {
    review {
      id
      rating
      content
    }
    errors
  }
}
```

**Delete a review:**
```graphql
mutation {
  deleteReview(input: { id: "1" }) {
    success
    errors
  }
}
```

**Ban a user:**
```graphql
mutation {
  banUser(input: { userId: "1" }) {
    user {
      id
      banned
    }
    errors
  }
}
```

**Unban a user:**
```graphql
mutation {
  unbanUser(input: { userId: "1" }) {
    user {
      id
      banned
    }
    errors
  }
}
```

## Performance Testing

### Generate 500,000 reviews

```bash
docker compose exec web rails runner db/seeds_performance.rb
```

### Measure performance

```bash
docker compose exec web rails runner scripts/measure_performance.rb
```

This will demonstrate that the home page query (50 books) has O(1) performance regardless of the number of reviews per book.

## Architecture Decisions

See `DECISIONES.md` for detailed information about:
- Ambiguous requirements and how they were resolved
- Trade-offs made and their costs
- What would be added before production
- What would be done with more time

## Key Implementation Details

### Cached Average Calculation
- Books store `average_rating` and `reviews_count` columns
- Averages are recalculated on review create/update/delete and user ban/unban
- Only non-banned user reviews are counted
- Uses PostgreSQL's `AVG()` with half-up rounding

### Concurrency Safety
- Uses `with_lock` (pessimistic locking) on Book records
- Ensures correct averages even with 200+ simultaneous operations
- Database-level unique constraint prevents duplicate reviews

### Banning System
- User model has `banned` boolean field
- Callback on `banned` status change triggers average recalculation
- Reviews from banned users are excluded from averages and queries
- Unbanning reactivates reviews automatically

## Testing Coverage

- ✅ Average calculation with half-up rounding (edge cases)
- ✅ Minimum 3 reviews threshold
- ✅ Retroactive banning (averages update when users are banned)
- ✅ Review edit/delete cycle
- ✅ Uniqueness constraint under concurrency
- ✅ GraphQL mutations and queries
- ✅ Database locking behavior

## Notes

- The current implementation uses `User.first` as a placeholder for authentication
- In production, replace with proper authentication (JWT, Devise, etc.)
- The system is designed to handle high-volume review campaigns
- Performance is O(1) for listing books regardless of review count
