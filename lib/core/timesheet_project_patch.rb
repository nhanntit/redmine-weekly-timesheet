require_dependency 'project'

module TimesheetProjectPatch

  def self.included(base)
    base.class_eval do
      unloadable

      has_many :selected_issues, :dependent => :delete_all

    end
  end

end

Project.send(:include, TimesheetProjectPatch)