# frozen_string_literal: true
# require 'rubygems'
# require 'bundler'
# require 'bundler/setup'
# Bundler.require

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'active_record'
require 'pry'
require 'pg'
require 'erb'
require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'gmail'
require './class'
require './function'

enable :sessions

before do
  unless request.path == '/login' || request.path == '/signup' || session[:id]
    session[:notice] = {color: "pink darken-4", message: "ログインして下さい", icon: "error"}
    return redirect '/login'
  end
  @user = User.find(session[:id]) if session[:id]
  @message = session.delete :notice
end

# not_found do
#   erb :not_found
# end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end


# トップページ
get '/' do
  redirect '/login'
end

# ログインページ
get '/login' do
  return erb :login, layout: :none
end

# ログイtン
post '/login' do
  user = User.find_by(password: params[:password])
  if user && User.find_by(email: params[:email])
    session[:id] = user[:id]
    session[:notice] = {color: "blue darken-4", message: "ログインしました", icon: "check_circle"}
    # 返却日を過ぎている履歴を探す
    active_histories = History.where(user_borrow_id: session[:id]).where(status_id: 1).select("deadline")
    today = Time.now
    active_histories.each{|history|
      if today > history.deadline
        session[:notice] = {color: "red", message: "返却期限が過ぎた本があります", icon: "priority_high"}
        redirect '/books'
      end
    }
    redirect '/books'
  else
    session[:notice] = {color: "pink darken-4", message: "入力情報を確認してください", icon: "error"}
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
  @email = h(params[:email])
  @password = h(params[:password])
  @user_name = h(params[:name])

  user = User.new(email: @email, password: @password, name: @user_name)
  if user.save
    redirect '/login'
    
  else
    session[:notice] = {color: "yellow darken-1", message:"そのメールアドレスはすでに使用されています", icon: "error"}
    redirect '/signup'
  end
end

# マイページページ
get '/mypage' do
  redirect '/' unless session[:id]

  # 多対多の関係をhas_thoroughで表現
  @user = User.find(session[:id])
  @my_books = @user.books
  # @authoers = Book.include(:authoer_maps)
  @authoers = Authoermap.all

  @all_books = Book.all

    # history関連
  @book_borrowed_logs = History.where(user_borrow_id: session[:id]).where.not(status_id: 3).where.not(status_id: 0) #status_id 1 -> 本を貸し借り処理済み
  @book_lending_logs = History.where(user_owner_id: session[:id]).where.not(status_id: 3).where.not(status_id: 0) #status_id 1 -> 本を貸し借り処理済み
  @request_logs = History.where(user_owner_id: session[:id]).where(status_id: 0) #status_id 0 -> リクエスト承認待ち
  return erb :mypage
end

post '/mybook/private' do
  Bookownermap.where(book_id: params[:book_id_to_private]).where(user_id: session[:id]).update(be_public: 'false')
  session[:notice] = {color: "yellow darken-1", message: "公開停止しました", icon: "pause_circle_filled"}
  redirect '/mypage#mybooks'
end

post '/mybook/delete' do
  Bookownermap.where(book_id: params[:book_id_delete]).where(user_id: session[:id]).delete_all
  session[:notice] = {color: "blue-grey darken-1", message: "削除しました", icon: "delete"}
  redirect '/mypage#mybooks'
end

post '/mybook/public' do
  Bookownermap.where(book_id: params[:book_id_to_public]).where(user_id: session[:id]).update(be_public: 'true')
  session[:notice] = {color: "light-blue", message: "公開しました", icon: "public"}
  redirect '/mypage#mybooks'
end

post '/request/agree' do
  book_agreed_id = params[:agree]
  target_book = History.where(book_id: book_agreed_id).where(user_owner_id: session[:id]).where(status_id: 0)
  target_book.update(status_id: 1)
  session[:notice] = {color: "blue darken-1", message: "リクエストを許可しました", icon: "check_circle"}
  redirect '/mypage#lend'
end

post '/request/disagree' do
  book_disagreed_id = params[:disagree]
  target_book = History.where(book_id: book_disagreed_id).where(user_owner_id: session[:id]).where(status_id: 0)
  target_book.update(status_id: 3)
  session[:notice] = {color: "red darken-1", message: "リクエストを拒否しました", icon: "pan_tool"}
  redirect '/mypage#request'
end

post '/request/return' do
  book_return_id = params[:return]
  target_book = History.where(book_id: book_return_id).where(user_borrow_id: session[:id]).where(status_id: 1)
  target_book.update(status_id: 2)
  session[:notice] = {color: "light-green darken-1", message: "返却確認待ちです", icon: "sentiment_satisfied_alt"}
  redirect '/mypage#borrow'
end

post '/request/finish' do
  book_finish_id = params[:finish]
  target_book = History.where(book_id: book_finish_id).where(user_owner_id: session[:id]).where(status_id: 2)
  target_book.update(status_id: 3)
  session[:notice] = {color: "yellow darken-1", message: "返却確認をしました", icon: "insert_emoticon"}
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
  # @authoers = Book.includes(:authoermap)
  @authoers = Authoermap.all
  return erb :books
end

get '/books/new' do
  redirect '/' unless session[:id]
  erb :add_book
end

post '/books/new' do
  redirect '/' unless session[:id]
    # begin
    user_id = session[:id]
    isbn = h(params[:isbn])
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
    if params[:existing_id]
      extist_tag_ids = params[:existing_id].map{|id| id.to_i}
      extist_tag_ids.each {|extist_tag_id|
        Tagmap.create(book_id: new_book.id, tag_id: extist_tag_id)
      }
    end

    # 新しいタグマップを結びつける
    if params[:new_tags]
      new_tags = h(params[:new_tags]).split(",").to_a
      new_tags.each do |new_tag|
        new_tag = Tag.create(tag_name: tag, user_id: user_id)
        Tagmap.create(book_id: new_book.id, tag_id: new_tag.id)
      end
    end
    redirect '/books'
  # rescue
  #   redirect '/books/manual'
  # end
end

get '/books/manual' do
  redirect '/' unless session[:id]
  return erb :add_manual
end

post '/books/manual' do
  redirect '/' unless session[:id]
  title = h(params[:title])
  authoers = h(params[:authoer]).split(",").to_a
  description = h(params[:description])
  new_tags = h(params[:new_tags]).split(",").to_a
  @thumbnail_name = params[:file][:filename]
  thumbnail = params[:file][:tempfile]
  isbn = h(params[:isbn])

  File.open("./public/images/#{@thumbnail_name}", 'wb') do |f|
    f.write(thumbnail.read)
  end

  new_book = Book.create(title: title, description: description, thumbnail: "/images/#{@thumbnail_name}", isbn: isbn)
  authoers.each do |authoer_name|
    Authoermap.create(name: authoer_name.to_s, book_id: new_book.id)
  end
  Bookownermap.create(user_id: session[:id], book_id: new_book.id)
  new_tags.each do |new_tag|
    new_tag = Tag.create(tag_name: new_tag, user_id: session[:id])
    Tagmap.create(book_id: new_book.id, tag_id: new_tag.id)
  end

  redirect '/books'
end

get '/books/:id' do
  redirect '/' unless session[:id]
   if Book.find(params[:id])
    @book = Book.find(params[:id])
  else
    # not_found
  end
  @tags = @book.tags
  @users = @book.users
  @authoers = Authoermap.where(book_id: params[:id])
  return erb :detail
end

post '/books/request' do
  user_borrow_id = session[:id]
  user_owner_id = params[:user_owner_id].to_i
  book_id = params[:book_id].to_i
  # 本の持ち主を絞り込む
  owner_maps = Bookownermap.where(book_id: book_id)
  History.create(
    user_owner_id: user_owner_id,
    user_borrow_id: user_borrow_id,
    book_id: book_id,
    status_id: 0
  )
  send_notify(user_owner_id, book_id)
  session[:notice] = {color: "teal darken-2", message: "リクエストを送信しました", icon: "done"}
  redirect '/books'
end


get '/search' do
  splited_keywords = params[:keyword].split(/[[:blank:]]+/)
  @searched_books = []
  splited_keywords.each do |keyword|
    next if keyword == ""
    sql = "SELECT DISTINCT books.id, books.title, books.thumbnail FROM books INNER JOIN  bookownermaps ON books.id = bookownermaps.book_id WHERE TITLE LIKE '%#{keyword}%' AND bookownermaps.be_public = true;"
    # activerecord での書き方
      # Book.joins(:bookownermaps).select("books.id, books.title, books.thumbnail").where('books.title LIKE ?',"%Ruby%").distinct
    @searched_books += Book.find_by_sql(sql)
  end
  # @searched_books.uniq!
  if @searched_books.empty?
    return redirect '/books'
  end #検索で”hoge”入力　=> リダイレクトされたおk


  @search_type = "キーワード検索"
  @search_element = params[:keyword]
  # @authoers = Book.include(:authoer_maps)
  @authoers = Authoermap.all
  erb :serch
end

get '/search/tags/:tagid' do
  tag_id = params[:tagid].to_i
  # sql = "select * from books INNER JOIN tagmaps on books.id = tagmaps.book_id INNER JOIN bookownermaps ON books.id = bookownermaps.book_id WHERE tagmaps.tag_id = #{tag_id}"
  @searched_books = Book.joins(:bookownermaps).joins(:tagmaps).select("books.id, books.title, books.thumbnail").where('tagmaps.tag_id = ?', "#{tag_id}")
  @search_type = "タグ"
  @search_element = Tag.find(tag_id).tag_name
  @authoers = Book.include(:authoer_maps)
  erb :serch
end
