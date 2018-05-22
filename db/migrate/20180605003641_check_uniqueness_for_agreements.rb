class CheckUniquenessForAgreements < ActiveRecord::Migration[5.2]
  def change
    change_column_null :agreements, :name, false
    change_column_null :agreements, :email, false
    change_column_null :agreements, :agreement_version, false
  end
end
