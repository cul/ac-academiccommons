class DataFeed < Grape::API
  content_type :json, 'application/json'
  default_format :json

  params do
    requires :key
  end

  desc 'Retrived data feed for key. Key maps to a set of preconfigured search results'
  get '/data_feed/:key' do
    # check authorization
    # error! 'Access Denied', 401 if credentials not valid
    feed = if params[:key] == 'dissertations'
             { type: 'Theses', degree_level: 'Dissertations' }
           else
             error! 'Feed key invalid', 403
           end


  end
end
