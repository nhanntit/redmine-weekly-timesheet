module TimesheetHelper

  include TimelogHelper

  # return projects that logged user is manager including sub-project
  def get_monitoring_projects
    @projects = []
    User.current.members.each do |member|
      @projects << member.project
      member.roles.each { |r|
        if r.name == 'Manager'
          sub_projects = Project.where('parent_id = ?', member.project_id)
          sub_projects.each { |s_p| @projects << s_p } if sub_projects
        end
      }
    end
    return @projects.uniq
  end

  # return members of projects in uniq
  def get_monitoring_members(projects)
    @members = {}
    @members = [:name => "<< #{l(:label_me)} >>", :id => User.current.id.to_s] if User.current.logged?
    temp = @project.dup if @project
    projects.each { |project|
      @project = project # @project is used for authorize_for function
      if authorize_for(:timesheet, :show_member_timesheet)
        project.users.each { |m|
          mb = [:name => m.name, :id => m.id.to_s]
          flag = @members.index(mb[0])
          @members += mb if (flag == nil && m.id != User.current.id)
        }
      end
    }
    @project = temp # return origin value for @project
    return @members.sort_by { |m| m[:name] }
  end

  def get_selected_issue_per_projects(projects, user_id, date)
    mon = return_to_monday(date)
    p_ids = []
    projects.each { |p| p_ids << p.id.to_s }
    sun = return_to_sun(date)
    mon_string = get_sql_time_string(mon)
    sun_string = get_sql_time_string(sun)
    issues = SelectedIssue.includes(:issue)
                 .where("user_id = #{user_id} AND date >= '#{mon_string}' AND date <= '#{sun_string}' AND project_id IN ('#{p_ids.join("','")}')")
                 .order("id asc").map(&:issue).reject {|issue| issue.nil?}
    return issues
  end

  def get_selected_issue(user_id, date)
    mon = return_to_monday(date)
    sun = return_to_sun(date)
    mon_string = get_sql_time_string(mon)
    sun_string = get_sql_time_string(sun)
    issues = SelectedIssue.includes(:issue)
                 .where("user_id = #{user_id} AND date >= '#{mon_string}' AND date <= '#{sun_string}'")
                 .order("id asc").map(&:issue).reject {|issue| issue.nil?}
    return issues
  end

  def convert_to_time(date)
    date = date.to_time unless date.is_a?(Time)
    return date
  end

  def get_date_from_year_week(yw_string)
    firstday = Date.today
    if !yw_string.blank?
      case
        when yw_string.length < 3
          week_number = yw_string.to_i
          firstday = Date.new(Date.today.year, 1, 1)
          firstday = return_to_first_week(firstday)
          firstday += 7*(week_number-1)
        when yw_string.length == 4
          y_number = yw_string.to_i
          firstday = Date.new(y_number, 1, 1)
          firstday = return_to_first_week(firstday)
        else
          yw_array = Array.new
          temp = yw_string.split('-')
          temp.each { |t| yw_array << Integer(t) }
          firstday = Date.new(yw_array[0], 1, 1)
          firstday = return_to_first_week(firstday)
          firstday += 7*(yw_array[1]-1)
      end
    end
    return firstday
  end

  def return_to_first_week(day)
    first_week = Date.civil(day.year, day.month, day.day).cweek
    while first_week != 1
      day += 7
      first_week = Date.civil(day.year, day.month, day.day).cweek
    end
    return day
  end

  #this function is called one time at the beginning of the deployment to load all time entry to time sheet. After that, we have to disable it
  def load_time_entry_to_time_sheet()
    temp_array = Array.new
    puts "temp_array: #{temp_array}"
    year = 0
    week = 0
    time_entries = TimeEntry.order(:spent_on)
    time_entries.each { |te|
      puts "Begin one time entry"
      puts "time entry spent_on: #{te.spent_on}"
      te_mon = return_to_monday(te.spent_on)
      te_week = te.tweek
      puts "time entry's week: #{te_week}"
      te_year = te.tyear
      puts "temp year: #{year},temp week: #{week},time entry year: #{te_year},time entry week: #{te_week}"
      if te_year == year && te_week == week
        puts "time is equal"
        key = "#{te.user_id}_#{te.issue_id}"
        puts "key of time entry: #{key}"
        found = false
        puts "temp array each{"
        temp_array.each { |ta|
          puts "temp array key: #{ta.to_s}, time entry key: #{key.to_s}"
          if (ta.to_s == key.to_s)
            found = true
            puts "found: #{found}"
            break;
          end
        }
        puts "}"
        puts "found after check(found = true mean nothing to do): #{found}"
        if found == false
          puts "add because found == false"
          selected_issue = SelectedIssue.new
          selected_issue.issue_id = te.issue_id
          selected_issue.user_id = te.user_id
          selected_issue.date = te.spent_on
          selected_issue.project_id = te.project_id
          selected_issue.save if te.issue_id && te.user_id && te.spent_on && te.project_id
          temp_array << key
          puts "temp array after add: #{temp_array}"
        end
      else
        puts "time is not equal"
        temp_array = []
        puts "temp array new: #{temp_array}"
        mon = te_mon
        sun = return_to_sun(te_mon)
        mon_string = get_sql_time_string(mon)
        sun_string = get_sql_time_string(sun)
        puts "mon_string: #{mon_string}"
        puts "sun_string: #{sun_string}"
        selected_issue = SelectedIssue.where("date >= '#{mon_string}' AND date <= '#{sun_string}'")
        selected_issue.each { |se| temp_array << "#{se.user_id}_#{se.issue_id}" }
        puts "temp array after query selected issue: #{temp_array}"
        key = "#{te.user_id}_#{te.issue_id}"
        puts "Time entry key: #{key}"
        found = false
        puts "temp array.each{"
        temp_array.each { |ta|
          puts "temp array key: #{ta.to_s}, time entry key: #{key.to_s}"
          if ta.to_s == key.to_s
            found = true
            puts "found: #{found}"
            break;
          end
        }
        puts "}"
        puts "found after check(found = true mean nothing to do): #{found}"
        if (found == false)
          puts "add because found == false"
          selected_issue = SelectedIssue.new
          selected_issue.issue_id = te.issue_id
          selected_issue.user_id = te.user_id
          selected_issue.date = te.spent_on
          selected_issue.project_id = te.project_id
          selected_issue.save if te.issue_id && te.user_id && te.spent_on && te.project_id
          temp_array << key
          puts "temp array after add: #{temp_array}"
        end
        year = te_year
        puts "new temp year: #{year}"
        week = te_week
        puts "new temp week: #{week}"
      end
      puts " ", " "
    }
  end

  def get_percent_done_per_date(issue, date)
    journals = issue.journals.joins(:details).where("date(journals.created_on) = '#{date}' and journal_details.prop_key = 'done_ratio'").select('journal_details.value').last
    return journals.value.to_s + "%" if journals
    return ''
  end

  ## upgrade from 3.6.5.1
  def calendar_timesheet_for(field_id)
    # calendar_headers_tags = include_calendar_headers_tags || ""
    # calendar_headers_tags +
        javascript_tag("timesheetDatepickerOptions = jQuery.extend({}, datepickerOptions);
                        timesheetDatepickerOptions.onSelect = function(dateText, inst) {
                          var date = getWeekNumber(new Date(dateText));
                          alert(date);
                          $(this).val( date[0] + '-' + date[1] );
                        };
                        $('##{field_id}').datepicker(timesheetDatepickerOptions); ")
  end

  ## update
  def get_sql_time_string(date)
    # sql_time_string = "#{date.year}-#{date.month}-#{date.day}"
    date.strftime('%Y-%m-%d %H:%M:%S')
  end

  def return_to_monday(current_time)
    while current_time.wday != 1 #if current_time is not monday, move it to sunday (the beginning of the week)
      current_time -= 1 #move to the previous day
    end
    return current_time
  end

  def return_to_sun(current_time)
    while current_time.wday != 0 #if current_time is not mon, move it to mon (the end of the week)
      current_time += 1 #move to the next day
    end
    return current_time
  end

  #get data on table time_entries with condition and plus hours spent
  def hours_spent_on(issue, user_id, date)
    time_entrys = TimeEntry.where("issue_id = #{issue.id} and user_id = #{user_id} and spent_on LIKE '#{date.to_date}'")
    @hours = 0
    time_entrys.each { |te| @hours += te.hours }
    return @hours
  end

  #get data on table time_entries with condition
  def get_time_entry(issue, user_id, date)
    TimeEntry.where("issue_id = #{issue.id} and user_id = #{user_id} and spent_on LIKE '#{date}'")
  end

  def efforts_plan_on(issue, user_id, date)
    result = {}
    mon = return_to_monday(date)
    sun = return_to_sun(date)
    mon_string = get_sql_time_string(mon)
    sun_string = get_sql_time_string(sun)
    efforts_plan = EffortPlan.where("issue_id = #{issue.id} and user_id = #{user_id} and plan_on >= '#{mon_string}' AND plan_on <= '#{sun_string}'").order(:plan_on)
    efforts_plan.each { |ep| result[ep.plan_on.to_date.to_s] = ep }
    return result
  end


  def load_repeat_efforts(issue, user_id, date)
    result = []
    current_day = get_sql_time_string(date)
    efforts = EffortPlan.where("issue_id = #{issue.id} and user_id = #{user_id} and plan_on > '#{current_day}'").order(:plan_on)
    efforts.each { |ep| result << ep.plan_on.to_s }
    return result
  end

end