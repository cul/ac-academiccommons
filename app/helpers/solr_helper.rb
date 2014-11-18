module SolrHelper
  
  
  def getAuthorsUni(pid)

    result = Blacklight.solr.find(:fl => 'author_uni', :fq => 'pid:"' + pid + '"')["response"]["docs"]
    return result.first[:author_uni] || []
  end  
  
  def getItem(pid)

    result = Blacklight.solr.find(:fl => 'author_uni,id,handle,title_display,free_to_read_start_date', :fq => 'pid:"' + pid + '"')["response"]["docs"]
    
      item = Item.new
      item.pid = result.first[:id]
      item.title = result.first[:title_display]
      item.handle = result.first[:handle]
      item.free_to_read_start_date = result.first[:free_to_read_start_date]
      item.authors_uni = result.first[:author_uni].first.split(', ') || []
      
    return item
  end    
  

end # =============================================================== #
