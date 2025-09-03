class SolrDocumentsController < ApplicationController
  include Blacklight::Catalog

  def rsolr
    @rsolr ||= AcademicCommons::Utils.rsolr
  end

  def authenticate
    status = :unauthorized
    authenticate_with_http_token do |token, options|
      # TODO : secrets to credentials
      (Rails.application.secrets.index_api_key || '').tap do |valid_api_key|
        status = (valid_api_key == token) ? :ok : :forbidden
      end
    end
    status
  end

  def update
    logger.debug "reindexing #{params[:id]}"
    unless (status = authenticate) == :ok
      render status: status, plain: ''
      return
    end
    # if no id, return bad request (400)
    unless params[:id]
      render plain: 'missing id parameter', status: :bad_request
      return
    end
    begin
      obj = ActiveFedora::Base.find(params[:id])

      # Using direct solr query to update document without soft commiting.
      # autoCommit will take care of presisting the new document. This change
      # was required in order to support multiple publishing requests from Hyacinth.
      solr_doc = obj.to_solr
      ActiveFedora::SolrService.add(solr_doc)

      expire_fragment('repository_statistics')

      aggregator = obj.is_a?(ContentAggregator)
      notify_authors_of_new_item(solr_doc) if aggregator

      location_url = aggregator ? solr_document_url(solr_doc['cul_doi_ssi']) : content_download_url(solr_doc['cul_doi_ssi'])
      response.headers['Location'] = location_url
      render status: :ok, plain: ''
    rescue ActiveFedora::ObjectNotFoundError => e
      render status: :not_found, plain: ''
    end
  end

  def destroy
    logger.debug "removing #{params[:id]} from index"
    unless (status = authenticate) == :ok
      render status: status, plain: ''
      return
    end
    ids = [params[:id]]
    begin
      # get the members and collect ids
      obj = ActiveFedora::Base.find(params[:id])
      obj.list_members(true).each { |id| ids << id } if obj.respond_to? :list_members
      ids.each { |id| rsolr.delete_by_query("fedora3_pid_ssi:\"#{id}\"") }
      rsolr.commit
    rescue Exception => e
      logger.warn e.message
    end
    render status: :ok, plain: ''
  end

  def show
    unless (status = authenticate) == :ok
      render status: status, plain: ''
      return
    end
    doc = rsolr.find(filters: {fedora3_pid_ssi: "\"#{params[:id]}\""})['response']['docs'].first
    if doc
      render json: doc
    else
      render status: :not_found, plain: ''
    end
  end

  private

  # Checks to see if new item notification has been sent to author. If one has
  # already been sent does not sent another one.
  def notify_authors_of_new_item(solr_doc)
    doc = SolrDocument.new(solr_doc)
    ldap = Cul::LDAP.new

    unis = solr_doc.fetch('author_uni_ssim', [])
    preferred_emails = EmailPreference.preferred_emails(unis)

    preferred_emails.each do |uni, email|
      # Skip if notification was already sent.
      next if Notification.sent_new_item_notification?(solr_doc['cul_doi_ssi'], uni)

      begin
        name = (author = ldap.find_by_uni(uni)) ? author.name : nil
        success = true
        UserMailer.new_item_available(doc, uni, email, name).deliver_now
      rescue StandardError => e
        logger.error "Error Sending Email: #{e.message}"
        logger.error e.backtrace.join("\n ")
        success = false
      end
      Notification.record_new_item_notification(doc[:cul_doi_ssi], email, uni, success)
    end
  end
end
