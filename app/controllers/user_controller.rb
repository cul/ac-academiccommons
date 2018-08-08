class UserController < ApplicationController
  before_action :authenticate_user!

  layout 'dashboard'

  def account; end

  def my_works
    @pending_works = pending_works
    @embargoed_works = embargoed_works
    @current_works_with_stats = current_works_with_stats
  end

  private

  def pending_works
    results = AcademicCommons.search do |params|
      identifiers = current_user.deposits.map(&:hyacinth_identifier)
                                .compact.map { |i| "\"#{i}\"" }.join(' OR ')
                                .prepend('(').concat(')')
      params.filter('fedora3_pid_ssi', identifiers)
      params.aggregators_only
      params.field_list('fedora3_pid_ssi')
    end

    hyacinth_ids_in_ac = results.documents.map { |d| d[:fedora3_pid_ssi] }

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
    startdate = Date.current.prev_month.beginning_of_month
    enddate   = startdate.end_of_month
    solr_params = { q: nil, fq: ["author_uni_ssim:\"#{current_user.uid}\""] }

    AcademicCommons::Metrics::UsageStatistics.new(
      solr_params, startdate, enddate, order_by: 'titles'
    )
  end
end
