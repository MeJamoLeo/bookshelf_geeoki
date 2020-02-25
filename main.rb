# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'active_record'
require 'pry'
require 'pg'
require 'erb'

enable :sessions

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)

class User < ActiveRecord::Base
end

class Book < ActiveRecord::Base
end

class History < ActiveRecord::Base
end

class Tag < ActiveRecord::Base
end

class Tagmap < ActiveRecord::Base
end
class Bookownermap < ActiveRecord::Base
end
class Authoermaps < ActiveRecord::Base
end

# トップページ
get '/' do
  redirect '/login'
end

get '/login' do
  return erb :login, layout: :none
end

post '/login' do
  user = User.find_by(email: params[:email])

  if user && User.find_by(password: params[:password])
    binding.pry
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

get '/books' do
  binding.pry
  return redirect '/' unless User.find_by(id: session[:id])

  return erb :books
end

get '/books/id' do
  return erb :id
end

get '/mypage' do
  return erb :mypage
end

get '/users' do
  @users = User.all
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

# ----------------------------------------------------

post '/books/new' do
  @title = params[:title]
  @description = params[:description]
  @thumbnail = params[:thumbnail]

  @authoer = params[:authoer]
  @tag = params[:tag]

  Book.create(title: @title, description: @description, thumbnail: @thumbnail)
  # セッションで投稿したユーザーのidをゲットしたい
  @user_id = 1
  Tag.create(tag_name: @tag)
  Authoermap.create
end

get '/books/new' do
  erb :add_book
end
