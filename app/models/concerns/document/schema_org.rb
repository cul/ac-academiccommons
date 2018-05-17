module Document
  module SchemaOrg
    extend ActiveSupport::Concern

    ITEMTYPE_MAP = {
      'Abstracts'                            => 'http://schema.org/CreativeWork',
      'Articles'                             => 'http://schema.org/ScholarlyArticle',
      'Bibliographies'                       => 'http://schema.org/CreativeWork',
      'Chapters (layout features)'           => 'http://schema.org/CreativeWork',
      'Catalogs'                             => 'http://schema.org/CreativeWork',
      'Charts (graphic documents)'           => 'http://schema.org/CreativeWork',
      'Conference objects'                   => 'http://schema.org/CreativeWork',
      'Data (Information)'                   => 'http://schema.org/Dataset',
      'Data collection materials'            => 'http://schema.org/CreativeWork',
      'Documentaries (documents)'            => 'http://schema.org/CreativeWork',
      'Essays'                               => 'http://schema.org/CreativeWork',
      'Exhibition catalogs'                  => 'http://schema.org/CreativeWork',
      'Fiction'                              => 'http://schema.org/CreativeWork',
      'Interviews'                           => 'http://schema.org/Conversation',
      'Monographs'                           => 'http://schema.org/Book',
      'Music'                                => 'http://schema.org/MusicComposition',
      'Performances (creative events)'       => 'http://schema.org/CreativeWork',
      'Photographs'                          => 'http://schema.org/Photograph',
      'Presentations (Communicative Events)' => 'http://schema.org/CreativeWork',
      'Reports'                              => 'http://schema.org/CreativeWork',
      'Reviews'                              => 'http://schema.org/Review',
      'Software'                             => 'http://schema.org/SoftwareSourceCode',
      'Theses'                               => 'http://schema.org/CreativeWork',
      'Visual arts'                          => 'http://schema.org/VisualArtwork'
    }.freeze

    def itemtype
      type = to_semantic_values.fetch(:type, []).first
      Rails.logger.debug "Type: #{type}"
      ITEMTYPE_MAP.fetch(type, 'http://schema.org/CreativeWork')
    end
  end
end
