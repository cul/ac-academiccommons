class InfoController < ApplicationController
  include Blacklight::SearchHelper
  layout 'static_page'

  def about; end
  def policies; end
  def faq; end
  def developers; end
end
