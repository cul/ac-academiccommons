class Deposit < ApplicationRecord

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
