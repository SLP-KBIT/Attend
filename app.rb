#! /usr/local/bin/ruby

require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'date'
require 'digest/md5'

enable :sessions

get '/' do
  if session[:user]
    con = PGconn.connect('localhost', 5432, '', '', 'attend', 'attend_admin', '')
    if params[:date].nil?
      d = Date.today
      @date = "#{d.year}-#{d.month}-#{d.day}"
    else
      @date = params[:date]
    end
    res1 = con.exec("select sid, lname from member natural join (select * from attend where date='#{@date}') X where sid like '%g%' order by sid;")
    res2 = con.exec("select sid, lname from member natural join (select * from attend where date='#{@date}') X where sid like '%t%' order by sid;")
    @attends = res1.to_a + res2.to_a
    erb :index
  else
    @alert = session[:alert]
    session[:alert] = nil
    erb :login
  end
end

post '/login' do
  con = PGconn.connect('localhost', 5432, '', '', 'attend', 'attend_admin', '')
  hash = Digest::MD5.hexdigest(params[:pass])
  res = con.exec("select * from member where account='#{params[:account]}' and password='#{hash}'");
  if res.count == 0
    session[:alert] = "未登録か、入力値が不正です"
    redirect '/'
  else
    d = Date.today
    sid = res.first['sid']
    date = "#{d.year}-#{d.month}-#{d.day}"
    attend = con.exec("select * from attend where sid='#{sid}' and date='#{date}'")
    if attend.count == 0
      con.exec("insert into attend (sid, date) values ('#{sid}', '#{date}')")
    end
    session[:user] = res.first['sid']
    redirect '/'
  end
end

post '/logout' do
  session[:user] = nil
  redirect '/'
end

get '/user' do
  @alert = session[:alert]
  session[:alert] = nil
  erb :user
end

post '/user' do
  account = params[:account]
  lname = params[:lname]
  fname = params[:fname]
  sid = params[:sid]
  password = params[:password]
  password_confirmation = params[:password_confirmation]
  if account.empty? || lname.empty? || fname.empty? || sid.empty? || password.empty? || password_confirmation.empty?
    session[:alert] = "すべて必須です"
    redirect '/user'
  end
  unless password == password_confirmation
    session[:alert] = "パスワードが一致しません"
    redirect '/user'
  end
  hash = Digest::MD5.hexdigest(password)
  con = PGconn.connect('localhost', 5432, '', '', 'attend', 'attend_admin', '')
  con.exec("insert into member (account, fname, lname, sid, password) values ('#{account}', '#{fname}', '#{lname}', '#{sid}', '#{hash}');")
  session[:user] = sid
  d = Date.today
  date = "#{d.year}-#{d.month}-#{d.day}"
  con.exec("insert into attend (sid, date) values ('#{sid}', '#{date}')")
  redirect '/'
end

get '/hellobaka' do
  erb :user_edit
end

post '/edit' do
  sid = params[:sid]
  password = params[:pass]
  password_confirmation = params[:pass_conf]
  if sid.empty? || password.empty? || password_confirmation.empty?
    session[:alert] = "すべて必須です"
    redirect '/hellobaka'
  end
  unless password == password_confirmation
    session[:alert] = "パスワードが一致しません"
    redirect '/hellobaka'
  end
  con = PGconn.connect('localhost', 5432, '', '', 'attend', 'attend_admin', '')
  res = con.exec("select * from member where sid='#{sid}';")
  unless res.count == 1
    session[:alert] = "学籍番号が登録されていません"
    redirect '/hellobaka'
  end
  hash = Digest::MD5.hexdigest(password)
  con.exec("update member set password='#{hash}' where sid='#{sid}';")
  session[:alert] = "パスワードを変更しました"
  redirect '/'
end
