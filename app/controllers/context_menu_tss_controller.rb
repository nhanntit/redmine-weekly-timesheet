class ContextMenuTssController < ApplicationController
  unloadable

  helper :issues
  include IssuesHelper
  include TimelogHelper
  include TimesheetHelper
  helper :context_menus

  def issues
    render :inline => "<ul>#{l(:error_issue_not_exist)}</ul>".html_safe and return if params[:ids].blank?
    @issues = Issue.includes(:project).find(params[:ids])
    if @issues.size == 1
      @issue = @issues.first
      @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    else
      @allowed_statuses = @issues.map { |i| i.new_statuses_allowed_to(User.current) }.inject { |memo, s| memo & s }
    end
    @projects = @issues.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1

    @can = {:delete => (@project && User.current.allowed_to?(:delete_issues, @project))}
    @back = back_url

    @mode = params[:cmode]
    @current_time = params[:ct]
    @current_time = Date.parse(@current_time)
    @user_id = params[:user_id]
    @tempt = @current_time
    @error_logged_time = false
    @issues.each do |issue|
      7.times { |i|
        time_pattern = @tempt.strftime("%Y-%m-%d")
        hours_spent = hours_spent_on(issue, @user_id, Date.parse(time_pattern))
        if hours_spent > 0
          @error_logged_time = true
          break
        end
        @tempt += 1
        time_pattern = @current_time.strftime("%Y-%m-%d")
      }
      break if @error_logged_time
    end
    render :layout => false

  rescue ActiveRecord::RecordNotFound => exc
    puts exc
    render :inline => "<ul>#{l(:error_issue_not_exist)}</ul>".html_safe
  rescue Exception => exc
    puts exc
    puts exc.backtrace
    render :inline => "<ul>#{l(:error_context_menu_tss)}</ul>"
  end
end