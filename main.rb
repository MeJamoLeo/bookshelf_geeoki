require 'sinatra'
require 'sinatra/reloader'
require 'active_record'
require 'pry'
require 'pg'


client = PG::connect(
  :host => "localhost",
  :user => 'leo',
  :password => '',
  :dbname => "library_geek")

# トップページ
get '/login' do
  @current_directry = Dir.pwd.split('/').last;
  return erb :login
end

post '/login' do
  @email = params[:email]
  @password = params[:password]

  if
  redirect '/books'
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


get '/users' do
  sql = "select * from users;"
  @users = db.exec_params(sql).to_a
  # @users の戻り値のサンプル
  # [
  #   {
  #     "id" => "1",
  #     "name" => "kinjo",
  #     "email" => "kinjo@mail.com",
  #     "password" => "kinjo"
  #   },
  #   {
  #     "id" => "2",
  #     "name" => "higa",
  #     "email" => "higa@mail.com",
  #     "password" => "higa"
  #   }
  # ]

  erb :users
end