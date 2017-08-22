require_dependency 'issue'

module TimesheetIssuePatch

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      has_many :selected_issues, :dependent => :delete_all
      has_many :effort_plan, :dependent => :delete_all
      has_many :users, :through => :selected_issues

      after_save :add_issue_to_timesheet

      include TimesheetHelper
    end
  end

  module InstanceMethods
      # Add the issue in my timesheet when save an issue
      def add_issue_to_timesheet
        log_date = (self.created_on == self.updated_on && self.start_date) ? self.start_date : Date.today
        mon_string = get_sql_time_string(return_to_monday(log_date))
        sun_string = get_sql_time_string(return_to_sun(log_date))
        selected_issue = SelectedIssue.where("user_id = #{User.current.id} AND issue_id = #{self.id} AND date >= '#{mon_string}' AND date <= '#{sun_string}' ").first
        if !selected_issue
          selected_issue = SelectedIssue.new
          selected_issue.issue_id = self.id
          selected_issue.user_id = User.current.id
          selected_issue.date = log_date
          selected_issue.project_id = self.project_id
          selected_issue.save
        end
        true
      rescue Exception => exc
        puts exc
        puts exc.backtrace
        true
      end

  end

end

Issue.send(:include, TimesheetIssuePatch)