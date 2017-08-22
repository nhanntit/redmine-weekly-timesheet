class TimesheetController < ApplicationController
  unloadable

  helper :issues
  include IssuesHelper
  include TimelogHelper
  helper :custom_fields
  helper :timesheet_query
  include TimesheetQueryHelper
  helper :sort
  include SortHelper
  helper :timesheet
  include TimesheetHelper

  before_filter :set_default_value

  def set_default_value
    @current_time = params[:current_time].present? ? Date.parse(params[:current_time]) : Date.today
    @mode = params[:mode] ? params[:mode] : "all"
    @user_id = params[:user_id].blank? ? User.current.id : params[:user_id]
    @monitoring_projects = get_monitoring_projects
    @monitoring_members = get_monitoring_members(@monitoring_projects)
    @timesheet_user = User.find_by_id(@user_id)

  end

  def index
    params[:reset_query] = 'true'
    @selected_issues = query_selected_issues
    respond_to do |format|
      format.html { render :action => 'index' }
    end
  end

  def load_user_timesheet
    if params[:values] && params[:values][:member_id] && params[:values][:member_id][0]
      @user_id = params[:values][:member_id][0]
      @timesheet_user = User.find_by_id(@user_id)
    end
    @time_entry = TimeEntry.new
    @selected_issues = query_selected_issues
    render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query}
  end

  def select_week
    @time_entry = TimeEntry.new
    @selected_issues = query_selected_issues
    render :partial => 'grid', :user_id => @user_id,  :locals => {:query => @timesheet_query} #, :project_id => params[:project_id]
  end


  def logtime
    @mode = params[:mode]
    #@project = Project.find(params[:project_id])
    @selected_issues = query_selected_issues
    issue_id = (params[:time_entry] || {})['issue_id']
    @issue = Issue.find_by_id(issue_id.to_i) if !issue_id.blank?
    @project = @issue.project if @issue
    @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => Date.today)
    @time_entry.attributes = params[:time_entry]
    call_hook(:controller_timelog_edit_before_save, {:params => params, :time_entry => @time_entry})
    if request.post? && @time_entry.save
      call_hook(:controller_timelog_edit_after_save, {:params => params, :time_entry => @time_entry})
      flash.now[:notice] = l(:notice_logtime_successful)
      @time_entry = TimeEntry.new
      render :partial => 'grid', :user_id => @user_id,  :locals => {:query => @timesheet_query} #, :project_id => @project.id
    else
      flash.now[:notice] = l(:notice_logtime_unsuccessful)
      @time_entry = TimeEntry.new
      render :partial => 'grid', :user_id => @user_id,  :locals => {:query => @timesheet_query} #, :project_id => @project.id
    end
  end

  def plantime
    flag = true
    #@project = Project.find(params[:project_id])
    issue_id = params[:issue_id]
    plan_on = params[:plan_on]
    plan_id = params[:plan_id]
    hours = params[:plan_hours]
    comment = params[:plan_comment]
    status_repeat_textbox = params[:operators_repeat_status_id]
    @selected_issues = query_selected_issues
    if status_repeat_textbox =='' || status_repeat_textbox.nil?
      if plan_id == 'notplanedyet'
        @effort_plan = EffortPlan.new(:issue_id => issue_id, :user_id => @user_id, :plan_on => plan_on, :hour => hours, :comment => comment)
      else
        @effort_plan = EffortPlan.find(plan_id)
        @effort_plan.hour = hours
        @effort_plan.comment = comment
      end
      flag = @effort_plan.save
    else
      next_plan_on = plan_on
      temp = 0
      issue_added = false
      while temp < status_repeat_textbox.to_i
        if next_plan_on.to_date.wday != 6 && next_plan_on.to_date.wday != 0
          @effort_plan = EffortPlan.where('plan_on = ? AND issue_id = ?', next_plan_on, issue_id).first
          if !@effort_plan
            @effort_plan = EffortPlan.new
            @effort_plan.issue_id = issue_id
            @effort_plan.user_id = @user_id
            @effort_plan.plan_on = next_plan_on
            @effort_plan.hour = hours
            @effort_plan.comment = comment
          else
            @effort_plan.hour = hours
            @effort_plan.comment = comment
            @effort_plan.plan_on = next_plan_on
          end
          @effort_plan.save
          temp += 1
        else
          if !issue_added && next_plan_on.to_date.wday == 6
            next_week = Date.civil(next_plan_on.to_date.year, next_plan_on.to_date.month, next_plan_on.to_date.day).cweek + 1
            date = get_date_from_year_week(next_week.to_s)
            selected_issue = SelectedIssue.where('date = ? AND issue_id = ? AND project_id = ?', date, issue_id, Issue.find(issue_id).project_id).first
            if !selected_issue
              selected_issue = SelectedIssue.new
              selected_issue.issue_id = issue_id
              selected_issue.user_id = User.current.id
              selected_issue.date = date
              selected_issue.project_id = Issue.find(issue_id).project_id
              selected_issue.save
            end
            issue_added = true
          end
        end
        next_plan_on = next_plan_on.to_date + 1
        issue_added = false
      end
    end

    if request.post? and flag
      flash.now[:notice] = l(:notice_plantime_successful)
      @time_entry = TimeEntry.new
      render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query} #, :project_id => @project.id
    else
      flash.now[:notice] = l(:notice_plantime_unsuccessful)
      @time_entry = TimeEntry.new
      render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query} #, :project_id => @project.id
    end
  end

  def remove
    mon = return_to_monday(@current_time)
    sun = return_to_sun(@current_time)
    mon_string = get_sql_time_string(mon)
    sun_string = get_sql_time_string(sun)
    removed_issue = SelectedIssue.where("issue_id = #{params[:issue_id]} AND user_id = #{User.current.id} AND date >= '#{mon_string}' AND date <= '#{sun_string}'").first
    if removed_issue
      removed_issue.destroy
      @time_entry = TimeEntry.new
      @selected_issues = query_selected_issues
      flash.now[:notice] = l(:notice_remove_selected_issue_successful)
      render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query} #, :project_id => @time_entry.project
    else
      @time_entry = TimeEntry.new
      @selected_issues = query_selected_issues
      flash.now[:notice] = l(:notice_remove_selected_issue_unsuccessful)
      render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query} #, :project_id => @time_entry.project
    end
  end

  #This function used for "Delete" in context-menu
  def remove_cm
    @ids = params[:ids]
    redirect_to :action => "index" and return if @ids.blank?
    @ids.each do |issue_id|
      mon = return_to_monday(@current_time)
      sun = return_to_sun(@current_time)
      mon_string = get_sql_time_string(mon)
      sun_string = get_sql_time_string(sun)
      removed_issue = SelectedIssue.where("issue_id = #{issue_id} AND user_id = #{User.current.id} AND date >= '#{mon_string}' AND date <= '#{sun_string}'").first
      if removed_issue
        removed_issue.destroy
        @time_entry = TimeEntry.new
        @selected_issues = query_selected_issues
      else
        @time_entry = TimeEntry.new
        @selected_issues = query_selected_issues
        @message = l(:notice_remove_selected_issue_unsuccessful)
        render :action => 'index', :project_id => @project, :current_time => @current_time, :mode => @mode, :timesheet_query => @timesheet_query
        return
      end
    end
    @message = l(:notice_remove_selected_issue_successful)
    render :action => 'index', :project_id => @project, :current_time => @current_time, :mode => @mode, :timesheet_query => @timesheet_query
  end

  def goto
    @current_time = get_date_from_year_week(params[:goto])
    @selected_issues = query_selected_issues
    @time_entry = TimeEntry.new if !@time_entry
    render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query} #, :project_id => params[:project_id]
  end

  def changemode
    mode = params[:cbmode]
    @mode = mode == "on" ? "all" : "logtime"
    @selected_issues = query_selected_issues
    @time_entry = TimeEntry.new if !@time_entry
    render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query} #, :project_id => params[:project_id]
  end

  def copyfrom
    from_time = get_date_from_year_week(params[:copyfrom])
    if @user_id.to_s == User.current.id.to_s
      source_issues = get_selected_issue(@user_id, from_time)
      target_issues = get_selected_issue(@user_id, @current_time)
    else
      source_issues = get_selected_issue_per_projects(@monitoring_projects, @user_id, from_time)
      target_issues = get_selected_issue_per_projects(@monitoring_projects, @user_id, @current_time)
    end
    copy_issues = source_issues - target_issues
    copy_issues.each { |ci|
      newSI = SelectedIssue.new
      newSI.issue_id = ci.id
      newSI.user_id = @user_id
      newSI.date = @current_time
      newSI.project_id = ci.project_id
      newSI.save
    }
    @selected_issues = query_selected_issues
    @time_entry = TimeEntry.new if !@time_entry
    flash.now[:notice] = l(:notice_copy_successful)
    render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query} #, :project_id => params[:project_id]
  end

  def copyto
    copy_time = get_date_from_year_week(params[:copyto])
    if @user_id.to_s == User.current.id.to_s
      target_issues = get_selected_issue(@user_id, copy_time)
      source_issues = get_selected_issue(@user_id, @current_time)
    else
      target_issues = get_selected_issue_per_projects(@monitoring_projects, @user_id, copy_time)
      source_issues = get_selected_issue_per_projects(@monitoring_projects, @user_id, @current_time)
    end
    copy_issues = source_issues - target_issues
    copy_issues.each { |ci|
      newSI = SelectedIssue.new
      newSI.issue_id = ci.id
      newSI.user_id = @user_id
      newSI.date = copy_time
      newSI.project_id = ci.project_id
      newSI.save
    }
    @current_time = copy_time
    @selected_issues = query_selected_issues
    @time_entry = TimeEntry.new if !@time_entry
    flash.now[:notice] = l(:notice_copy_successful)
    render :partial => 'grid', :user_id => @user_id, :locals => {:query => @timesheet_query} #, :project_id => params[:project_id]
  end

  def add
    # @project = Project.find(params[:project_id])
    # #@monitoring_projects = get_monitoring_projects
    date = get_date_from_year_week(params[:datetoadd])
    #date = convert_to_time(date)
    #date = return_to_monday(date)
    param_ids = params[:ids].to_s
    ids = param_ids.split(',')
    requested_ids = []
    ids.each { |id| requested_ids << Integer(id) }
    selected_issues = get_selected_issue(User.current.id, date)
    ids_temp = selected_issues.collect { |p| p.id }
    ids3 = requested_ids - ids_temp
    ids3.each { |id|
      newSI = SelectedIssue.new
      newSI.issue_id = id
      newSI.user_id = User.current.id
      newSI.date = date
      newSI.project_id = Issue.find(id).project_id
      newSI.save
    }
    flash[:notice] = l(:notice_successful_add_to_timesheet)
    redirect_to :back
  end

  #This function used for "Copy To" in context-menu
  def add_in_timesheet
    redirect_to :action => 'index' and return if request.get?
    begin
      @current_time = params[:ts_current_time].blank? ? Date.today : Date.parse(params[:ts_current_time])
      @selected_issues = query_selected_issues
      date = get_date_from_year_week(params[:datetoadd])
      #date = convert_to_time(date)
      #date = return_to_monday(date)
      param_ids = params[:ids]
      ids = param_ids.split(',')
      requested_ids = Array.new
      ids.each { |id| requested_ids << Integer(id) }
      selected_issues = get_selected_issue(User.current.id, date)
      ids_temp = selected_issues.collect { |p| p.id }
      ids3 = requested_ids - ids_temp
      ids3.each { |id|
        newSI = SelectedIssue.new
        newSI.issue_id = id
        newSI.user_id = User.current.id
        newSI.date = date
        newSI.project_id = Issue.find(id).project_id
        newSI.save
      }
      @time_entry = TimeEntry.new if !@time_entry
      @message = l(:notice_successful_add_to_timesheet)
      render :action => 'index', :project_id => @project, :current_time => @current_time, :mode => @mode

    rescue Exception => exc
      puts exc.backtrace
      flash[:notive] = "The system raised an exception #{exc.class}, please try again!"
      redirect_to :action => 'index'
      return
    end
  end

  def export_to_csv
    @monitoring_projects = get_monitoring_projects
    @monitoring_members = get_monitoring_members(@monitoring_projects)
    while @current_time.wday != 1
      @current_time -= 1 #move to the previous day
    end

    export = Redmine::Export::CSV.generate do |csv|
      # header row
      csv_header = ["User Name", "Project", "ID", "Issue", "Target version", "Issue category", "Tracker", "Due Date"]
      7.times do |i|
        time = @current_time.strftime("%a \n %m /%d")
        csv_header = csv_header + [time]
        @current_time += 1
      end
      csv << csv_header + ["Total"]

      # data rows
      arr_vtotal = Array.new
      time_pattern = @current_time.strftime("%Y-%m-%d")
      @monitoring_members.each do |member|
        vtotal_sun = vtotal_mon = vtotal_tue = vtotal_wed = vtotal_thu = vtotal_fri = vtotal_sat = vtotal = 0
        @current_time -= 7
        if member[:id] == User.current.id.to_s
          @selected_issues = get_selected_issue(User.current.id, @current_time).sort_by { |a| [a.project_id] }
          member[:name] = User.current.name
        else
          @selected_issues = get_selected_issue_per_projects(@monitoring_projects, member[:id].to_i, @current_time).sort_by { |a| [a.project_id] }
        end
        arr = Array.new
        @current_time += 7
        if (@selected_issues.present?)
          @selected_issues.each do |se|
            @current_time -= 7

            ### begin : add columns to exported csv file
            tracker = se.tracker.name if se.tracker
            category = se.category.name if se.category
            target_version = se.fixed_version.name if se.fixed_version
            arr = [member[:name], se.project.name, se.id, se.subject, target_version, category, tracker, se.due_date]

            total = 0
            7.times do |i|
              hours_spent = hours_spent_on(se, member[:id].to_i, @current_time)
              total += hours_spent
              arr = arr + [hours_spent]
              case i
                when 0 then
                  vtotal_sun += hours_spent
                when 1 then
                  vtotal_mon += hours_spent
                when 2 then
                  vtotal_tue += hours_spent
                when 3 then
                  vtotal_wed += hours_spent
                when 4 then
                  vtotal_thu += hours_spent
                when 5 then
                  vtotal_fri += hours_spent
                when 6 then
                  vtotal_sat += hours_spent
                else
                  puts("date time error")
              end #end case
              @current_time += 1
            end
            arr = arr + [total]
            csv << arr
          end
          arr_vtotal = ["", "", "", "", "", "", "", "Total"]
          vtotal = vtotal_sun + vtotal_mon + vtotal_tue + vtotal_wed + vtotal_thu + vtotal_fri + vtotal_sat
          arr_vtotal = arr_vtotal + [vtotal_sun] + [vtotal_mon] + [vtotal_tue]+ [vtotal_wed]+ [vtotal_thu]+ [vtotal_fri] + [vtotal_sat] + [vtotal]
          csv << arr_vtotal
        end
      end
    end

    send_data ("\uFEFF" << export), :type => 'text/csv; header=present', :disposition => "attachment", :filename => 'Timesheet.csv'
  end

  def ajax_load_form_log_time
    @mode = params['mode'] ? params['mode'] : "all"
    issue = Issue.find_by_id(params['issue_id'].to_i) if !params['issue_id'].blank?
    project = issue.project if issue
    @time_entry ||= TimeEntry.new(:project => project, :issue => issue, :user => User.current)
    @activity_logtime_in_timesheet = TimeEntryActivity.where("active = 1").where(:project_id => nil)
    activity_setting_in_project = TimeEntryActivity.where("active = 0").where(:project_id => issue.project_id)
    array_activity_name = activity_setting_in_project.collect { |p| p.name }
    if activity_setting_in_project.exists? && array_activity_name.count != @activity_logtime_in_timesheet.collect { |p| p.name }.count
      for i in array_activity_name
        @activity_logtime_in_timesheet = @activity_logtime_in_timesheet.reject { |p| p.name == "#{i}"}
      end
    end
  end
end
