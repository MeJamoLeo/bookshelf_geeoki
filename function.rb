def get_book_info(isbn)
require 'net/http'
require 'uri'
require 'json'
require 'pry'

goole_books_url = 'https://www.googleapis.com/books/v1/volumes?q=isbn:'

uri = URI.parse(goole_books_url + isbn)
json = Net::HTTP.get(uri)
result = JSON.parse(json)

book_info = result.dig("items", 0, "volumeInfo")

{
  title: book_info.dig("title"),
  description: book_info.dig("description"),
  thumbnail: book_info.dig("imageLinks", "thumbnail"),
  authoers: book_info.dig("authors")
}
# title = result.dig("items", 0, "volumeInfo", "title")



end