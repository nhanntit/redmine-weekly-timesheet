#These hooks are defined to add the issue in my timesheet automatically whenever users log time or update the issue with logged spent time.
require_relative '../../app/helpers/timesheet_helper'
class TimesheetHooks < Redmine::Hook::ViewListener

  include TimesheetHelper

  # Add the issue in my timesheet when update logged time
  def controller_timelog_edit_after_save(context = {})
    params = context[:params]
    issue_id = params[:time_entry]['issue_id']
    return unless issue_id
    log_date = params[:time_entry]['spent_on']
    return unless log_date
    time_entry = context[:time_entry]
    log_date = Date.parse(log_date)
    mon = return_to_monday(log_date)
    sun = return_to_sun(log_date)
    mon_string = get_sql_time_string(mon)
    sun_string = get_sql_time_string(sun)
    selected_issue = SelectedIssue.where("user_id = #{User.current.id} AND issue_id = #{issue_id} AND date >= '#{mon_string}' AND date <= '#{sun_string}' ").first
    if !selected_issue
      selected_issue = SelectedIssue.new
      selected_issue.issue_id = issue_id.to_i
      selected_issue.user_id = User.current.id
      selected_issue.date = log_date
      selected_issue.project_id = time_entry.project_id
      selected_issue.save
    end
  rescue Exception => exc
    puts exc
    puts exc.backtrace
  end

  # Add "Add to my timesheet" into issue's menu context
  def view_issues_context_menu_end(context = {})
    output = ''
    issues = context[:issues]
    return output unless issues
    project = issues[0].project
    ids_temp = issues.collect { |p| p.id }.join(',')
    output << javascript_include_tag('timesheet', :plugin => 'weekly_timesheet')
    menu_item = "<a href='javascript:void(0)' class='icon icon-add' id='cmLink' onclick=\"showChooseDate('topabc','#{ids_temp}','#{project.id}');return false;\">#{l(:label_add_to_time_sheet)}</a>"
    output << "<div id='topabc'></div><li>#{menu_item}</li>".html_safe
    return output
  rescue Exception => exc
    puts exc
    puts exc.backtrace
  end

end