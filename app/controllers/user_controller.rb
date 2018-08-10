class UserController < ApplicationController
  before_action :authenticate_user!, except: :unsubscribe_monthly

  layout 'dashboard'

  def account; end

  def my_works
    @pending_works = pending_works
    @embargoed_works = embargoed_works
    @current_works_with_stats = current_works_with_stats
  end

  def unsubscribe_monthly
    author_id = params[:author_id].to_s

    begin
      raise 'Request missing parameters.' if author_id.blank? || params[:chk].blank?
      raise 'Cannot be verified.' unless Rails.application.message_verifier(:unsubscribe).verify(params[:chk]) == author_id

      epref = EmailPreference.find_or_initialize_by(author: author_id)
      epref.monthly_opt_out = true
      epref.save!

      flash[:success] = 'Unsubscribe request successful'
    rescue StandardError
      flash[:error] = 'There was an error with your unsubscribe request'
    end

    redirect_to root_url
  end

  private

  def pending_works
    current_user.deposits.to_a.keep_if do |deposit|
      deposit.hyacinth_identifier.blank?
    end
  end

  def embargoed_works
    AcademicCommons.search do |params|
      params.filter('author_uni_ssim', current_user.uid)
      params.embargoed_only
      params.aggregators_only
    end
  end

  def current_works_with_stats
    startdate = Date.current.prev_month.beginning_of_month
    enddate   = startdate.end_of_month
    solr_params = { q: nil, fq: ["author_uni_ssim:\"#{current_user.uid}\""] }

    AcademicCommons::Metrics::UsageStatistics.new(
      solr_params, startdate, enddate, order_by: 'titles'
    )
  end
end
