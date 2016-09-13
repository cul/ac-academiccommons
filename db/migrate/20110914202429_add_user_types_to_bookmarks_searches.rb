# -*- encoding : utf-8 -*-
class AddUserTypesToBookmarksSearches < ActiveRecord::Migration
  def self.up
    add_column :searches, :user_type, :string
    add_column :bookmarks, :user_type, :string
    if defined? Search
      Search.reset_column_information
      Search.update_all("user_type = 'user'")
    end
    if defined? Bookmark
      Bookmark.reset_column_information
      Bookmark.update_all("user_type = 'user'")
    end
  end

  def self.down
    remove_column :searches, :user_type, :string
    remove_column :bookmarks, :user_type, :string
  end
end
