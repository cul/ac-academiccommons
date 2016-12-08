class InfoController < ApplicationController
  include Blacklight::SearchHelper

  def about; end
  def policies; end
  def faq; end
end
