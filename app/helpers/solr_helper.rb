module SolrHelper
  
  
  def getAuthorsUni(pid)

    result = Blacklight.solr.find(:fl => 'author_uni', :fq => 'pid:"' + pid + '"')["response"]["docs"]
    return result.first[:author_uni] || []
  end  
  
  def getItem(pid)

    result = Blacklight.solr.find(:fl => 'author_uni,id,handle,title_display', :fq => 'pid:"' + pid + '"')["response"]["docs"]
    
      item = Item.new
      item.pid = result.first[:id]
      item.title = result.first[:title_display]
      item.handle = result.first[:handle]
      item.authors_uni = result.first[:author_uni]

    return item
  end    
  

end # =============================================================== #
