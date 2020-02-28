# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'active_record'
require 'pry'
require 'pg'
require 'erb'
require './class'
require 'function'

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
  erb :signup
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
  @books = @user.books
  @authoers = Authoermap.all

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

  title = book_info[:title]
  description = book_info[:description]
  thumbnail = book_info[:thumbnail]
  authoer_name = book_info[:authoers]

  tags = params[:tag].split(",").to_a

  new_book = Book.create(title: title, description: description, thumbnail: thumbnail, isbn: isbn, id: 6)
  binding.pry
  Authoermap.create(name: authoer_name)
  Bookownermap.create(user_id: user_id, book_id: new_book.id)


  tags.each do |tag|
    new_tag = Tag.create(tag_name: tag, user_id: user_id)
    Tagmap.create(book_id: new_book.id, tag_id: new_tag.id)
  end
end

get '/books/id' do
  return erb :id
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

  binding.pry

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
  binding.pry
  @tags = @book.tags
  binding.pry

  erb :'plain/tags', layout: :none
end
