require_dependency 'issues_helper'

module TimesheetIssueHelperPatch

  def self.included(base)
    base.class_eval do
      include TimesheetHelper
    end
  end

end

IssuesHelper.send(:include, TimesheetIssueHelperPatch)
