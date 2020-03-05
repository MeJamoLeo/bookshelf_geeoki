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

# ログインページ
get '/login' do
  return erb :login, layout: :none
end

# ログイン
post '/login' do
  user = User.find_by(password: params[:password])

  if user && User.find_by(email: params[:email])
    session[:id] = user[:id]
    redirect '/books'
  else
    redirect '/login'
  end
end

# ログアウト
get '/logout' do
  session.clear unless session[:id].nil?
  redirect '/'
end

# サインアップページ
get '/signup' do
  erb :signup, layout: :none
end

# サインアップ
post '/signup' do
  @email = params[:email]
  @password = params[:password]
  @user_name = params[:name]

  User.create(email: @email, password: @password, name: @user_name)
  redirect '/login'
end

# マイページページ
get '/mypage' do
  redirect '/' unless session[:id]

  # 多対多の関係をhas_thoroughで表現
  @user = User.find(session[:id])
  @my_books = @user.books
  @authoers = Authoermap.all

  @all_books = Book.all

    # history関連
  @book_borrowed_logs = History.where(user_borrow_id: session[:id]).where.not(status_id: 3) #status_id 1 -> 本を貸し借り処理済み
  @book_lending_logs = History.where(user_owner_id: session[:id]).where.not(status_id: 3).where.not(status_id: 0) #status_id 1 -> 本を貸し借り処理済み
  @request_logs = History.where(user_owner_id: session[:id]).where(status_id: 0) #status_id 0 -> リクエスト承認待ち
  return erb :mypage
end

post '/mybook/private' do
  Bookownermap.where(book_id: params[:book_id_to_private]).where(user_id: session[:id]).update(be_public: 'false')
  redirect '/mypage#mybooks'
end

post '/mybook/delete' do
  Bookownermap.where(book_id: params[:book_id_delete]).where(user_id: session[:id]).delete_all
  redirect '/mypage#mybooks'
end

post '/mybook/public' do
  Bookownermap.where(book_id: params[:book_id_to_public]).where(user_id: session[:id]).update(be_public: 'true')
  redirect '/mypage#mybooks'
end

post '/request/agree' do
  book_agreed_id = params[:agree]
  target_book = History.where(book_id: book_agreed_id).where(user_owner_id: session[:id]).where(status_id: 0)
  target_book.update(status_id: 1)
  redirect '/mypage#lend'
end

post '/request/disagree' do
  book_disagreed_id = params[:disagree]
  target_book = History.where(book_id: book_disagreed_id).where(user_owner_id: session[:id]).where(status_id: 0)
  target_book.update(status_id: 3)
  redirect '/mypage#request'
end

post '/request/return' do
  book_return_id = params[:return]
  target_book = History.where(book_id: book_return_id).where(user_borrow_id: session[:id]).where(status_id: 1)
  target_book.update(status_id: 2)
  redirect '/mypage#borrow'
end

post '/request/finish' do
  book_finish_id = params[:finish]
  target_book = History.where(book_id: book_finish_id).where(user_owner_id: session[:id]).where(status_id: 2)
  target_book.update(status_id: 3)
  redirect '/mypage#request'
end

# 本の一覧ページ
get '/books' do
  redirect '/' unless session[:id]
  selected_bookownermaps = Bookownermap.where(be_public: true).to_a
  book_ids = selected_bookownermaps.map{ |selected_bookownermap|
    selected_bookownermap.book_id
    }
  @books = book_ids.uniq.map{|book_id|
    Book.find(book_id)
  }
  @authoers = Authoermap.all
  return erb :books
end

get '/books/new' do
  redirect '/' unless session[:id]
  erb :add_book
end

post '/books/new' do
  redirect '/' unless session[:id]
  begin
    user_id = session[:id]
    isbn = params[:isbn]
    book_info = get_book_info(isbn)
    if Book.find_by(isbn: isbn)
      book_already_exists = Book.find_by(isbn: isbn)
      Bookownermap.create(user_id: user_id, book_id: book_already_exists.id)
      redirect '/books'
      return
    end
    
    new_book = Book.create(title: book_info[:title],description: book_info[:description],thumbnail: book_info[:thumbnail],isbn: isbn)

    book_info[:authoers].each do |authoer_name|
      Authoermap.create(name: authoer_name.to_s, book_id: new_book.id)
    end
    
    Bookownermap.create(user_id: user_id, book_id: new_book.id)
    # 既存のタグを結びつける
    extist_tag_ids = params[:existing_id].map{|id| id.to_i}
    extist_tag_ids.each {|extist_tag_id|
      Tagmap.create(book_id: new_book.id, tag_id: extist_tag_id)
    }
    
    # 新しいタグマップを結びつける
    binding.pry
    new_tags = params[:new_tags].split(",").to_a
    new_tags.each do |new_tag|
      new_tag = Tag.create(tag_name: tag, user_id: user_id)
      Tagmap.create(book_id: new_book.id, tag_id: new_tag.id)
    end
    redirect '/books'
  rescue
    redirect '/books/manual'
  end
end

get '/books/manual' do
  redirect '/' unless session[:id]
  return erb :add_manual
end

post '/books/manual' do
  redirect '/' unless session[:id]
  title = params[:title]
  authoers = params[:authoer].split(",").to_a
  description = params[:description]
  tags = params[:tags].split(",").to_a
  @thumbnail_name = params[:file][:filename]
  thumbnail = params[:file][:tempfile]
  isbn = params[:isbn]

  File.open("./public/images/#{@thumbnail_name}", 'wb') do |f|
    f.write(thumbnail.read)
  end

  new_book = Book.create(title: title, description: description, thumbnail: "/images/#{@thumbnail_name}", isbn: isbn)
  authoers.each do |authoer_name|
    Authoermap.create(name: authoer_name.to_s, book_id: new_book.id)
  end
  Bookownermap.create(user_id: session[:id], book_id: new_book.id)
  tags.each do |tag|
    new_tag = Tag.create(tag_name: tag, user_id: session[:id])
    Tagmap.create(book_id: new_book.id, tag_id: new_tag.id)
  end

  redirect '/books/manual'
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
      status_id: 0
    )
  end
  redirect '/books'
end


get '/tags' do
  erb :'parts/tag_checkbox'
end

post '/tags' do
  tag_ids = params[:id].map {|tag_id| tag_id.to_i}
  binding.pry
  redirect '/tags'
end