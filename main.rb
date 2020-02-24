require 'sinatra'
require 'sinatra/reloader'
require 'active_record'
require 'pry'
require 'pg'

def db
client = PG::connect(
  :host => "localhost",
  :user => 'leo',
  :password => '',
  :dbname => "library_geek")
end

# トップページ
get '/login' do
  @current_directry = Dir.pwd.split('/').last;
  return erb :login
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
  erb :users
end

# ----------------------------------------------------

get '/users/:id' do
  id = params[:id]
  sql = "select * from users where id = #{id};"
  users = db.exec_params(sql).to_a
  @user = users[0]
  # binding.pry
  # @user の戻り値のサンプル
  # {
  #   "id" => "1",
  #   "name" => "kinjo",
  #   "email" => "kinjo@mail.com",
  #   "password" => "kinjo"
  # }

  erb :users
end