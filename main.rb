require 'sinatra'
require 'sinatra/reloader'
require 'active_record'

# トップページ
get '/' do
  return erb :index
end

get '/login' do
  return erb :login
end

get '/signup' do
  return erb :signup
end

# 本の一覧ページ
get '/books' do
  return erb :books
end

# 本の詳細ページ
get '/books/:id' do
  return erb :book_about
end

# 承認リクエストをするページ
get '/books/:id/request' do
  return erb :rent_request
end

# 承認リクエストの完了を知らせるページ
get '/books/:id/requested' do
  return erb :requested
end

# 貸し出し完了を知らせるページ
get '/books/:id/thanks' do
  return erb :thanks
end

# 本を検索するページ
get '/search' do
  return erb :search
end

get '/mypage' do
  return erb :mypage
end


# 自分の新しい本を登録するページ
# ポップアップで登録フォームを出したい
post '/mypage/new' do
  
end
# -----------------------


get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

get '/' do
  return erb :
end

