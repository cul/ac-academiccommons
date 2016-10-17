module SolrHelper
  
  def getAuthorsUni(pid)

    result = blacklight_solr.find(:fl => 'author_uni', :fq => 'pid:"' + pid + '"')["response"]["docs"]
    return result.first[:author_uni] || []
  end

  def getItem(pid)

    result = blacklight_solr.find(:fl => 'author_uni,id,handle,title_display,free_to_read_start_date', :fq => 'pid:"' + pid + '"')["response"]["docs"]

      item = Item.new
      item.pid = result.first[:id]
      item.title = result.first[:title_display]
      item.handle = result.first[:handle]
      item.free_to_read_start_date = result.first[:free_to_read_start_date]

      item.authors_uni = []

      if(result.first[:author_uni] != nil)
        # item.authors_uni = result.first[:author_uni] || []
        item.authors_uni = fixAuthorsArray(result.first[:author_uni])
      end

    return item
  end

  def fixAuthorsArray(authors_uni)

    author_unis_clean = []

    authors_uni.each do | uni_str |
      author_unis_clean.push(uni_str.split(', '))
    end

    return author_unis_clean.flatten
  end


end # =============================================================== #
