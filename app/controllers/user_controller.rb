class UserController < ApplicationController
  before_action :authenticate_user!, except: :unsubscribe_monthly

  layout 'dashboard'

  def account
    @email_preference = current_user.email_preference
  end

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

      epref = EmailPreference.find_or_initialize_by(uni: author_id)
      epref.unsubscribe = true
      epref.save!

      flash[:success] = 'Unsubscribe request successful'
    rescue StandardError
      flash[:error] = 'There was an error with your unsubscribe request'
    end

    redirect_to root_url
  end

  private

  def pending_works
    return [] if current_user.deposits.blank?

    identifiers = current_user.deposits.map(&:hyacinth_identifier).compact

    if identifiers.present?
      results = AcademicCommons.search do |params|
        identifiers = identifiers.map { |i| "\"#{i}\"" }.join(' OR ')
                                 .prepend('(').concat(')')
        params.filter('fedora3_pid_ssi', identifiers)
        params.aggregators_only
        params.field_list('fedora3_pid_ssi')
      end

      hyacinth_ids_in_ac = results.documents.map { |d| d[:fedora3_pid_ssi] }
    else
      hyacinth_ids_in_ac = []
    end

    current_user.deposits.to_a.keep_if do |deposit|
      hyacinth_id = deposit.hyacinth_identifier
      hyacinth_id.blank? || !hyacinth_ids_in_ac.include?(hyacinth_id)
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
    options = {
      start_date:  Date.current.prev_month.beginning_of_month,
      end_date:    Date.current.prev_month.end_of_month,
      solr_params: { q: nil, fq: ["author_uni_ssim:\"#{current_user.uid}\""] }
    }

    AcademicCommons::Metrics::UsageStatistics.new(options)
                                             .calculate_lifetime
                                             .calculate_period
  end
end
