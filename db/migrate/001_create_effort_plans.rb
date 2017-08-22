class CreateEffortPlans < ActiveRecord::Migration
  def self.up
    create_table :effort_plans do |t|
      t.column :issue_id, :integer, :default => 0, :null => false
      t.column :user_id, :integer, :default => 0, :null => false
      t.column :comment, :string
      t.column :plan_on, :date, :null => false
      t.column :hour, :float
      t.timestamps :null => true
    end
  end

  def self.down
    drop_table :effort_plans
  end
end
