class CreateSelectedIssues < ActiveRecord::Migration
  def self.up
    create_table :selected_issues do |t|
      t.column :issue_id, :integer, :default => 0, :null => false
      t.column :user_id, :integer, :default => 0, :null => false
      t.column :project_id, :integer, :default => 0, :null => false
      t.column :date, :date
      t.timestamps :null => true
    end

  end

  def self.down
    drop_table :selected_issues
  end
end
