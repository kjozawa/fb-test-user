#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'haml'
require 'json'
require 'open-uri'
require 'pit'

config = Pit.get("facebook", :require => {
                   "app_id" => "you app id",
                   "app_secret" => "your app secret"
})

APP_ID = config['app_id']
APP_SECRET = config['app_secret']

get '/' do
  get_access_token
  res = `curl "https://graph.facebook.com/#{APP_ID}/accounts/test-users?#{@access_token}"`
  @json = JSON.parse res

  haml :index
end

private

def get_access_token
  url = "https://graph.facebook.com/oauth/access_token?client_id=#{APP_ID}&client_secret=#{APP_SECRET}&grant_type=client_credentials"
  unless @access_token
    open(url) do |f|
      @access_token = f.read
    end
  end
  @access_token
end
