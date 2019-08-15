module V1
  module Entities
    class ShortRecord < Grape::Entity
      expose(:id)         { |r| r.id }
      expose(:legacy_id)  { |r| r.legacy_id }
      expose(:title)      { |r| r.title }
      expose(:author)     { |r| r.author }
      expose(:abstract)   { |r| r.abstract }
      expose(:date)       { |r| r.date.to_s }
      expose(:department) { |r| r.department }
      expose(:subject)    { |r| r.subject }
      expose(:type)       { |r| r.type }
      expose(:language)   { |r| r.language }
      expose(:persistent_url) { |r| r.full_doi }

      expose(:resource_paths) do |r|
        r.assets.map { |a| "/doi/#{a.doi}/download" }
      end

      expose(:created_at)  { |r| r.created_at }
      expose(:modified_at) { |r| r.modified_at }
    end
  end
end
