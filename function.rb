def get_book_info(isbn)
require 'net/http'
require 'uri'
require 'json'
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
end


def create_tables(title, authoers, description, thumbnail, isbn, tags)
  new_book = Book.create(title: title,description: description,thumbnail: thumbnail, isbn: isbn)

  authoers.each do |authoer_name|
    Authoermap.create(name: authoer_name.to_s, book_id: new_book.id)
  end

  Bookownermap.create(user_id: session[:id], book_id: new_book.id)

  tags.each do |tag|
    new_tag = Tag.create(tag_name: tag, user_id: user_id)
    Tagmap.create(book_id: new_book.id, tag_id: new_tag.id)
  end
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end