require 'sinatra'
require 'sinatra/reloader'
require 'active_record'

# トップページ
get '/' do
  return erb :index
end

get '/books' do
  return erb :books
end

get '/books/id' do
  return erb :id
end

get '/mypage' do
  return erb :mypage
end