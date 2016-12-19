# -*- encoding : utf-8 -*-
class SolrDocumentsController < ApplicationController
  include Blacklight::Catalog

  def rsolr
    @rsolr ||= begin
      url = Rails.application.config.solr['url']
      RSolr.connect(:url => url)
    end
  end

  def authenticate
    status = :unauthorized
    authenticate_with_http_token do |token, options|
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
      render plain: "missing id parameter", status: :bad_request
      return
    end
    begin
      obj = ActiveFedora::Base.find(params[:id])
      obj.update_index
      location_url = obj.is_a?(ContentAggregator) ?
        catalog_url(params[:id]) :
        download_url(obj)
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
      ids.each { |id| rsolr.delete_by_id(id) }
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
    doc = rsolr.find(filters: {id: "\"#{params[:id]}\""})["response"]["docs"].first
    if doc
      render json: doc
    else
      render status: :not_found, plain: ''
    end
  end

  private
  def download_url(af_obj)
    download_params = {
      block: nil,
      uri: af_obj.pid,
      filename: nil,
      download_method: 'download'
    }
    block_ds = af_obj.downloadable_content
    if block_ds
      download_params[:block] = block_ds.dsid
      download_params[:filename] = block_ds.label.blank? ? af_obj.label : block_ds.label
    end
    fedora_content_url(download_params)
  end
end
