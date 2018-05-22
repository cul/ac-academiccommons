class AddUserRefToAgreements < ActiveRecord::Migration[5.2]
  def change
    add_reference :agreements, :user, foreign_key: true
  end
end
