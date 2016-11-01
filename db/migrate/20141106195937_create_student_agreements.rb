class CreateStudentAgreements < ActiveRecord::Migration
  def change
    unless table_exists?('student_agreements')
      create_table :student_agreements do |t|
        t.string :uni
        t.string :name
        t.string :email
        t.string :years_embargo
        t.string :thesis_advisor
        t.string :department

        t.timestamps
      end
    end
  end
end
