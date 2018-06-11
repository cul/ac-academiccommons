class DontRequireValuesForDeposits < ActiveRecord::Migration[5.2]
  def change
    change_column_null :deposits, :agreement_version, true
    change_column_null :deposits, :name, true
    change_column_null :deposits, :email, true
    change_column_null :deposits, :file_path, true
    change_column_null :deposits, :title, true
    change_column_null :deposits, :authors, true
    change_column_null :deposits, :abstract, true
  end
end
