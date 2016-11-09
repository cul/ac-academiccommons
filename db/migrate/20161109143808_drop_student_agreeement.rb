class DropStudentAgreeement < ActiveRecord::Migration
  def change
    drop_table :student_agreements
  end
end
