# frozen_string_literal: true
class FeaturedSearch < ActiveRecord::Base
  PROPERTIES_FILE = 'properties.yml'
  DESCRIPTION_FILE = 'description.md'

  belongs_to :feature_category
  has_many :featured_search_values, dependent: :destroy

  validates :slug, presence: true
  validates :label, presence: true
  validates :feature_category, presence: true
  validates :priority, presence: true
  validate :at_least_one_filter_value

  def at_least_one_filter_value
    return unless featured_search_values.reject(&:marked_for_destruction?).empty?
    errors.add(:filter_field, 'Must have at least one filter value')
  end

  accepts_nested_attributes_for :featured_search_values,
                                allow_destroy: true,
                                reject_if: proc { |atts| atts['value'].strip.blank? } # remove blank values

  def image_url
    thumbnail_url.present? ? thumbnail_url : feature_category.thumbnail_url
  end

  def export_attributes
    properties = JSON.parse(to_json(except: [:id, :description], include: [:feature_category, featured_search_values: { except: [:id, :featured_search_id] }]))
    properties['description'] = DESCRIPTION_FILE
    properties
  end

  # export a serialized featured search to a given directory
  # returns the exported search
  def export(directory)
    FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
    open(File.join(directory, DESCRIPTION_FILE), 'wb') { |io| io.write(description) }
    open(File.join(directory, PROPERTIES_FILE), 'wb') { |io| io.write(YAML.dump(export_attributes)) }
    self
  end

  # import a serialized featured search from a given directory
  # returns the imported search
  def self.import(directory)
    properties = import_attributes(directory)
    description_path = File.join(directory, properties.delete('description'))
    category_props = properties.delete('feature_category')
    category = FeatureCategory.find_by(field_name: category_props['field_name'])
    category ||= FeatureCategory.find(category_props['id'])
    raise "unknown category #{category_props['field_name']}" unless category
    imported_search = FeaturedSearch.find_or_initialize_by(slug: properties['slug'])
    featured_search_values = properties.delete('featured_search_values') || []
    imported_search.assign_attributes(properties)
    imported_search.feature_category = category
    import_search_values(imported_search, featured_search_values)
    imported_search.description = File.read(description_path)
    imported_search if imported_search.save!
  end

  def self.import_attributes(directory)
    properties_path = File.join(directory, PROPERTIES_FILE)
    raise "no FeaturedSearch export at #{properties_path}" unless File.exist?(properties_path)
    properties = YAML.safe_load(File.read(properties_path), aliases: true)
    raise "no FeatureCategory properties at #{properties_path}" unless properties.dig('feature_category', 'field_name')
    properties
  end

  def self.import_search_values(imported_search, values)
    imported_search.featured_search_values.each do |featured_search_value|
      if values.present?
        featured_search_value.assign_attributes(value: values.shift['value'])
      else
        featured_search_value.delete
      end
    end
    values.each { |value| imported_search.featured_search_values << FeaturedSearchValue.new(value: value['value']) }
  end
end
