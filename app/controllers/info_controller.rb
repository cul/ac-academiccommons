class InfoController < ApplicationController
  include Blacklight::SearchHelper

  def about; end

  def policies; end

  def faq; end

  def developers; end

  def credits; end
end
