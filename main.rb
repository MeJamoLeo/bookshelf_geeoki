# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'active_record'
require 'pry'
require 'pg'
require 'erb'
require './class'
require './function'

enable :sessions

# トップページ
get '/' do
  redirect '/login'
end

get '/login' do
  return erb :login, layout: :none
end

post '/login' do
  user = User.find_by(password: params[:password])

  if user && User.find_by(email: params[:email])
    session[:id] = user[:id]
    redirect '/books'
  else
    redirect '/login'
  end
end

get '/logout' do
  session.clear unless session[:id].nil?
  redirect '/'
end

get '/signup' do
  erb :signup, layout: :none
end

post '/signup' do
  @email = params[:email]
  @password = params[:password]
  @user_name = params[:name]

  User.create(email: @email, password: @password, name: @user_name)
  redirect '/login'
end

get '/mypage' do
  redirect '/' unless session[:id]

  # 多対多の関係をhas_thoroughで表現
  @user = User.find(session[:id])
  @my_books = @user.books
  @authoers = Authoermap.all

  @all_books = Book.all

    # history関連
  @book_borrowed_logs = History.where(user_borrow_id: session[:id]).where(status: 1) #status 1 -> 本を貸し借り処理済み
  @book_lending_logs = History.where(user_owner_id: session[:id]).where(status: 1) #status 1 -> 本を貸し借り処理済み
  @request_logs = History.where(user_owner_id: session[:id]).where(status: 0) #status 0 -> リクエスト承認待ち
  return erb :mypage
end

get '/books' do
  redirect '/' unless session[:id]
  @books = Book.all
  @authoers = Authoermap.all
  return erb :books
end

get '/books/new' do
  redirect '/' unless session[:id]
  erb :add_book
end

post '/books/new' do
  redirect '/' unless session[:id]

  user_id = session[:id]
  isbn = params[:isbn]
  book_info = get_book_info(isbn)

  if Book.find_by(isbn: isbn)
    book_already_exists = Book.find_by(isbn: isbn)
    Bookownermap.create(user_id: user_id, book_id: book_already_exists.id)
  end
  redirect '/books'
  return

  # title = book_info[:title]
  # description = book_info[:description]
  # thumbnail = book_info[:thumbnail]
  # authoer_names = book_info[:authoers]

  tags = params[:tag].split(",").to_a
  new_book = Book.create(title: book_info[:title], description: book_info[:description], thumbnail: book_info[:thumbnail], isbn: isbn)
  book_info[:authoers].each do |authoer_name|
    Authoermap.create(name: authoer_name.to_s, book_id: new_book.id)
  end
  Bookownermap.create(user_id: user_id, book_id: new_book.id)

  tags.each do |tag|
    new_tag = Tag.create(tag_name: tag, user_id: user_id)
    Tagmap.create(book_id: new_book.id, tag_id: new_tag.id)
  end

  redirect '/books'
end

get '/books/:id' do
  redirect '/' unless session[:id]
  @book = Book.find(params[:id])
  @tags = @book.tags
  @users = @book.users
  @authoers = Authoermap.where(book_id: params[:id])

  return erb :detail
end

post '/books/request' do
  user_borrow_id = session[:id]
  book_id = params[:book_id]
  owner_maps = Bookownermap.where(book_id: book_id)
  owner_maps.each do |owner_map|
    History.create(
      user_owner_id: owner_map.user_id,
      user_borrow_id: user_borrow_id,
      book_id: book_id,
      status: 0
    )
  end
  redirect '/books'
end























































# ----------------------------------------------------　plainフォルダ

get '/plain/books' do
  @books = Book.all
  @authoers = Authoermap.all
  return erb :'plain/books', layout: :none
end

get '/plain/mypage' do
  redirect '/' unless session[:id]
  @authoers = Authoermap.all

  @user = User.find(session[:id])
  @books = @user.books

  each @books do |book|
  @tags = book.tags
  end


  return erb :'plain/mypage'
end

get '/plain/books' do
  @books = Book.all
  @authoers = Authoermap.all
  return erb :'plain/books', layout: :none
end

get '/plain/tags' do
  redirect '/' unless session[:id]

  @book = Book.find(1)
  @tags = @book.tags

  erb :'plain/tags', layout: :none
end
