class AddUserRefToAgreements < ActiveRecord::Migration[5.2]
  def change
    add_reference :agreements, :user, type: :integer, foreign_key: true
  end
end
