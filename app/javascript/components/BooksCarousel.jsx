// app/javascript/components/BooksCarousel.jsx
import React, { useState, useEffect } from "react"

export default function BooksCarousel() {
  const [books, setBooks] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [currentIndex, setCurrentIndex] = useState(0)

  useEffect(() => {
    fetchTopBooks()
  }, [])

  const fetchTopBooks = async () => {
    try {
      const response = await fetch('/graphql', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify({
          query: `
            query {
              topBooks(limit: 50) {
                id
                title
                author
                averageRating
                reviewsCount
                averageRatingDisplay
              }
            }
          `
        })
      })

      const contentType = response.headers.get('content-type')
      if (!contentType || !contentType.includes('application/json')) {
        const text = await response.text()
        throw new Error(`Expected JSON response, got: ${contentType}. Response: ${text.substring(0, 200)}`)
      }

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      
      if (data.errors) {
        throw new Error(data.errors[0].message)
      }

      setBooks(data.data.topBooks)
      setLoading(false)
    } catch (err) {
      setError(err.message)
      setLoading(false)
    }
  }

  const fetchReviews = async (bookId) => {
    try {
      const response = await fetch('/graphql', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          query: `
            query {
              reviews(bookId: "${bookId}") {
                id
                rating
                content
                user {
                  id
                  name
                }
              }
            }
          `
        })
      })

      const data = await response.json()
      return data.data.reviews
    } catch (err) {
      console.error('Error fetching reviews:', err)
      return []
    }
  }

  const nextSlide = () => {
    setCurrentIndex((prev) => (prev + 1) % Math.ceil(books.length / 5))
  }

  const prevSlide = () => {
    setCurrentIndex((prev) => (prev - 1 + Math.ceil(books.length / 5)) % Math.ceil(books.length / 5))
  }

  const getVisibleBooks = () => {
    const startIndex = currentIndex * 5
    return books.slice(startIndex, startIndex + 5)
  }

  if (loading) {
    return (
      <div className="books-carousel-container">
        <div className="loading">Loading books...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="books-carousel-container">
        <div className="error">Error: {error}</div>
      </div>
    )
  }

  const visibleBooks = getVisibleBooks()

  return (
    <div className="books-carousel-container">
      <h2 className="carousel-title">Top 50 Books</h2>
      
      <div className="carousel-wrapper">
        <button className="carousel-nav prev" onClick={prevSlide}>
          ‹
        </button>
        
        <div className="carousel-track">
          {visibleBooks.map((book) => (
            <div key={book.id} className="book-card">
              <div className="book-info">
                <h3 className="book-title">{book.title}</h3>
                <p className="book-author">by {book.author}</p>
                <div className="book-rating">
                  <span className="rating-display">{book.averageRatingDisplay}</span>
                  <span className="reviews-count">({book.reviewsCount} reviews)</span>
                </div>
              </div>
              <div className="book-reviews-preview">
                <p className="reviews-label">Recent Reviews</p>
                <ReviewsPreview bookId={book.id} />
              </div>
            </div>
          ))}
        </div>
        
        <button className="carousel-nav next" onClick={nextSlide}>
          ›
        </button>
      </div>
      
      <div className="carousel-dots">
        {Array.from({ length: Math.ceil(books.length / 5) }).map((_, index) => (
          <button
            key={index}
            className={`dot ${index === currentIndex ? 'active' : ''}`}
            onClick={() => setCurrentIndex(index)}
          />
        ))}
      </div>
    </div>
  )
}

function ReviewsPreview({ bookId }) {
  const [reviews, setReviews] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchReviews()
  }, [bookId])

  const fetchReviews = async () => {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      
      const response = await fetch('/graphql', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken || '',
          'Accept': 'application/json',
        },
        body: JSON.stringify({
          query: `
            query {
              reviews(bookId: "${bookId}") {
                id
                rating
                content
                user {
                  id
                  name
                }
              }
            }
          `
        })
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      setReviews(data.data.reviews.slice(0, 3)) // Show only first 3 reviews
      setLoading(false)
    } catch (err) {
      console.error('Error fetching reviews:', err)
      setLoading(false)
    }
  }

  if (loading) {
    return <div className="reviews-loading">Loading reviews...</div>
  }

  if (reviews.length === 0) {
    return <div className="no-reviews">No reviews yet</div>
  }

  return (
    <div className="reviews-list">
      {reviews.map((review) => (
        <div key={review.id} className="review-item">
          <div className="review-header">
            <span className="review-author">{review.user.name}</span>
            <span className="review-rating">{'★'.repeat(review.rating)}{'☆'.repeat(5 - review.rating)}</span>
          </div>
          {review.content && <p className="review-content">{review.content}</p>}
        </div>
      ))}
    </div>
  )
}
