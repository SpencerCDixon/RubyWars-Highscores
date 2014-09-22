require 'sinatra'
require 'pg'

configure :development do
  require 'sinatra/reloader'
  set :database_config, { dbname: 'rubywars' }
end

configure :production do
  set :database_config, production_database_config
end

def production_database_config
  db_url_parts = ENV['DATABASE_URL'].split(/\/|:|@/)
  {
    user: db_url_parts[3],
    password: db_url_parts[4],
    host: db_url_parts[5],
    dbname: db_url_parts[7]
  }
end

def db_connection
  begin
    connection = PG.connect(settings.database_config)
    yield(connection)
  ensure
    connection.close
  end
end

def submit_score(name, score)
  sql = "INSERT INTO scores (name, score) VALUES ($1, $2)"
  db_connection do |db|
    db.exec_params(sql,[name, score])
  end
end

def all_scores
  sql = "SELECT * FROM scores ORDER BY score DESC limit 25"
  result = db_connection do |db|
    db.exec_params(sql)
  end
  result.to_a
end


get '/' do
  @scores = all_scores
  erb :index
end

post '/' do
  submit_score(params[:name], params[:score])
  redirect '/'
end
