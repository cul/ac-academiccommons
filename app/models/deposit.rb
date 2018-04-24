class Deposit < ApplicationRecord

  validates_presence_of :agreement_version
  validates_presence_of :name
  validates_presence_of :email
  validates_presence_of :file_path
  validates_presence_of :title
  validates_presence_of :authors
  validates_presence_of :abstract

end
