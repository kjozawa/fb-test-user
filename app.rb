# -*- encoding: utf-8 -*-
#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'sass'
require 'json'
require 'open-uri'
require 'pit'
require 'sequel'
require 'rack-flash'

configure do
#  use Rack::MethodOverride
  use Rack::Session::Cookie
  use Rack::Flash

  Sequel::Model.plugin(:schema)
  Sequel.connect("sqlite://fb-test-users.db")

  # APP_ID = config['app_id']
  # APP_SECRET = config['app_secret']
end

class Users < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
      integer :user_id
      string :access_token
      string :email
      string :password
    end
    create_table
  end
end

class User
  attr_accessor :id, :login_url, :delete_url, :email, :password

  def initialize(json, u)
    @id = json['id']
    @login_url = json['login_url']
    @delete_url = "https://graph.facebook.com/#{json['id']}?method=delete&access_token=#{json['access_token']}"
    if u
      p u.values
      @email = u.values[:email]
      @password = u.values[:password]
    end
  end
end

before do
  @config = Pit.get("facebook", :require => {
                     "app_id" => "you app id",
                     "app_secret" => "your app secret"
                   })
  get_access_token
end

get '/style.css' do
  sass :style
end

get '/' do
  res = `curl "https://graph.facebook.com/#{@config['app_id']}/accounts/test-users?#{@access_token}"`
  json = JSON.parse res

  @users = []
  json['data'].each do |line|
    u = Users.find(:user_id => (line['id']))
    @users << User.new(line, u)
  end

  haml :index
end

delete '/user/' do
  id = params[:id]
  res = `curl -d "" "https://graph.facebook.com/#{id}?method=delete&#{@access_token}"`
  if res == 'true'
    flash[:notice] = "Delete Success!!"
  else
    flash[:error] = "Delete Fail!!"
  end

  redirect '/'
end

put '/user' do
  res = `curl -d "" "https://graph.facebook.com/#{@config['app_id']}/accounts/test-users?installed=true&permissions=read_stream&method=post&#{@access_token}"`
  json = JSON.parse res

  if json['error']
    flash[:error] = json['error']['message']
  else
    Users.create({
                  :user_id => json['id'].to_i,
                  :access_token => json['access_token'],
                  :email => json['email'],
                  :password => json['password']
                })
   flash[:notice] = "New User !!"
  end
  redirect '/'
end

private

def get_access_token
  url = "https://graph.facebook.com/oauth/access_token?client_id=#{@config['app_id']}&client_secret=#{@config['app_secret']}&grant_type=client_credentials"
  unless @access_token
    open(url) do |f|
      @access_token = f.read
    end
  end
  @access_token
end
