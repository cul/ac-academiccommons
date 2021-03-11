# frozen_string_literal: true
class FeaturedSearch < ActiveRecord::Base
  PROPERTIES_FILE = 'properties.yml'
  DESCRIPTION_FILE = 'description.md'

  belongs_to :feature_category

  def image_url
    thumbnail_url.present? ? thumbnail_url : feature_category.thumbnail_url
  end

  # export a serialized featured search to a given directory
  # returns the exported search
  def export(directory)
    properties = JSON.parse(to_json(except: :description, include: :feature_category))
    FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
    open(File.join(directory, DESCRIPTION_FILE), 'wb') { |io| io.write(description) }
    properties['description'] = DESCRIPTION_FILE
    open(File.join(directory, PROPERTIES_FILE), 'wb') { |io| io.write(YAML.dump(properties)) }
    self
  end

  # import a serialized featured search from a given directory
  # returns the imported search
  def self.import(directory)
    properties_path = File.join(directory, PROPERTIES_FILE)
    raise "no FeaturedSearch export at #{properties_path}" unless File.exist?(properties_path)
    properties = YAML.safe_load(File.read(properties_path))
    description_path = File.join(directory, properties.delete('description'))
    category_props = properties.delete('feature_category')
    raise "no FeatureCategory properties at #{properties_path}" unless category_props&.fetch('field_name', nil)
    category = FeatureCategory.find_by(field_name: category_props['field_name'])
    category ||= FeatureCategory.find(category_props['id'])
    raise "unknown category #{category_props['field_name']}" unless category
    imported_search = FeaturedSearch.find_or_initialize_by(id: properties.delete('id'))
    imported_search.assign_attributes(properties)
    imported_search.feature_category = category
    imported_search.description = File.read(description_path)
    imported_search if imported_search.save!
  end
end
