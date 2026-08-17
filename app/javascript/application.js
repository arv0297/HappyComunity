import "./controllers"
import React from "react"
import BooksCarousel from "./components/BooksCarousel"
import { createRoot } from "react-dom/client"

document.addEventListener("DOMContentLoaded", () => {
    const el = document.getElementById("books-carousel")
    if (el) createRoot(el).render(<BooksCarousel />)
})