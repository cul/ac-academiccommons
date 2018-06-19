class UserController < ApplicationController
  before_action :authenticate_user!

  def account; end

  def my_works
    @pending_documents = pending_documents
    @current_documents = current_documents
  end

  private

  def pending_documents
    current_user.deposits.to_a.keep_if do |deposit|
      deposit.hyacinth_identifier.blank?
    end
  end

  def current_documents
    results = AcademicCommons.search do |parameters|
      parameters.filter('author_uni_ssim', current_user.uid)
                .sort_by('title_ssi asc')
    end
    results.docs
  end
end
