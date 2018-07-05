class Deposit < ApplicationRecord
  COPYRIGHT_STATUS = [
    'In Copyright',
    'No Copyright'
  ].freeze

  # validates_presence_of :agreement_version
  # validates_presence_of :name
  # validates_presence_of :email
  # validates_presence_of :file_path
  # validates_presence_of :title
  # validates_presence_of :authors
  # validates_presence_of :abstract

  validate :one_creator_must_be_present, on: :create
  validates :title, :abstract, :year, :rights_statement, :files, presence: true, on: :create

  has_many_attached :files

  belongs_to :user, optional: true

  store :metadata, accessors: %i[title creators abstract year doi license rights_statement notes], coder: JSON

  def one_creator_must_be_present
    one_creator_present = creators.any? do |c|
      c[:first_name].present? && c[:last_name].present? && c[:uni].present?
    end
    errors.add(:creators, 'must have one creator with first name, last name and uni.') unless one_creator_present
  end
end
