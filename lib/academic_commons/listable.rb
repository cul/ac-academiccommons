module AcademicCommons
  module Listable
    def build_resource_list(document, include_inactive = false)
      return [] unless free_to_read?(document)
      obj_display = document.fetch("id", [])
      uri_prefix = "info:fedora/"

      member_search = {
      q: '*:*',
      qt: 'standard',
      fl: '*',
      fq: ["cul_member_of_ssim:\"info:fedora/#{obj_display}\""],
      rows: 10000,
      facet: false
      }
      member_search[:fq] << "object_state_ssi:A" unless include_inactive
      response = Blacklight.default_index.connection.get 'select', params: member_search
      docs = response['response']['docs']
      logger.debug "standard qt got #{docs.length} resources"
      docs.map do |member|
        res = {}
        member = SolrDocument.new(member)
        member_pid = member["id"].sub(uri_prefix, "")

        res[:pid] = member_pid
        res[:filename] = member['downloadable_content_label_ss']
        dsid = member['downloadable_content_dsid_ssi']
        res[:download_path] = fedora_content_path(:download, member_pid, dsid, res[:filename])
        res[:content_type] = member['downloadable_content_type_ssi']

        res
      end
    rescue StandardError => e
      Rails.logger.error e.message
      return []
    end
  end
end
