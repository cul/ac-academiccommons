class AddCurrentStudentColumnsToDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :current_student, :boolean
    add_column :deposits, :degree_program, :string
    add_column :deposits, :academic_advisor, :string
    add_column :deposits, :thesis_or_dissertation, :string
    add_column :deposits, :degree_earned, :string
    add_column :deposits, :embargo_date, :string
    add_column :deposits, :previously_published, :boolean
    add_column :deposits, :article_version, :string
    add_column :deposits, :keywords, :text
  end
end
