require_dependency 'user'

module TimesheetUserPatch

  def self.included(base)
    base.class_eval do
      unloadable

      has_many :selected_issues, :dependent => :delete_all
      has_many :effort_plan, :dependent => :delete_all
      has_many :issues, :through => :selected_issues

    end
  end

end

User.send(:include, TimesheetUserPatch)