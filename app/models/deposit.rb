class Deposit < ApplicationRecord
  RIGHTS_STATEMENTS = [
    'No Copyright - United States',
    'No Copyright - Other Known Legal Restrictions',
    'In Copyright',
    'In Copyright - Educational Use Permitted',
    'In Copyright- Non-Commercial Use Permitted',
    'In Copyright- Unknown Rightsholder',
    'Copyright Undetermined'
  ].freeze

  LICENSE = [
    'Attribution (CC BY)',
    'Attribution-ShareAlike (CC BY-SA)',
    'Attribution-NoDerivs (CC BY-ND)',
    'Attribution-NonCommercial (CC BY-NC)',
    'Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)',
    'Attribution-NonCommercial-NoDerivs (CC BY-NC-ND)',
    'No license attributed'
  ].freeze
  # validates_presence_of :agreement_version
  # validates_presence_of :name
  # validates_presence_of :email
  # validates_presence_of :file_path
  # validates_presence_of :title
  # validates_presence_of :authors
  # validates_presence_of :abstract

  has_many_attached :files

  # store :metadata, accessors: [:title, :abstract, :doi, :notes, :doi], coder: JSON

  # add new columns for
  #  hyacinth_identifier
  #  proxied
  #

end
