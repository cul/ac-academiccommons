class ChangeAcademicAdvisorToThesisAdvisor < ActiveRecord::Migration[6.0]
  def change
	rename_column :deposits, :academic_advisor, :thesis_advisor
  end
end
