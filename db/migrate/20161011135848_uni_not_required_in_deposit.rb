class UniNotRequiredInDeposit < ActiveRecord::Migration
  def change
    change_column_null :deposits, :uni, true
  end
end
