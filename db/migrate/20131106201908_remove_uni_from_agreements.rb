class RemoveUniFromAgreements < ActiveRecord::Migration
  def up
    remove_column :agreements, :uni
  end

  def down
    add_column :agreements, :uni, :string
  end
end
