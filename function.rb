
require 'sinatra/reloader'
def get_book_info(isbn)

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




def send_notify(user_id, book_id)
  #　メールを送る相手の情報
  target_user = User.find(user_id)
  target_email = target_user[:email]
  target_name = target_user[:name]

  # 本の情報
  target_book = Book.find(book_id)
  book_title = target_book[:title]


gmail = Gmail.new( ENV['USER_NAME'],  ENV['USER_PASS'])
  email_subject = "本の貸し出しリクエストが届きました"
  email_body = "
    <h1>GeeOkiBooks</h1>
    <h2>本の貸し出しリクエスト</h2>
    <p>#{target_name}さんから以下の貸し出しリクエストがあります．</p>
    <hr>
    <p> > #{book_title}</p>
    <hr>"
    #実際にメールを送信する部分
    message = gmail.generate_message do
      to target_email
      subject email_subject
      html_part do
        content_type "text/html; charset=UTF-8"
        body email_body
      end
    end
  gmail.deliver(message)
  gmail.logout
end

