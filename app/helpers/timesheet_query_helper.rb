module TimesheetQueryHelper

  #Fake Queries Models
  class TimesheetQuery

    include TimesheetHelper
    include Redmine::I18n
    include QueriesHelper

    # include
    #include ::ActiveRecord::ConnectionAdapters::Quoting

    attr_accessor :monitoring_projects
    attr_accessor :monitoring_members
    attr_accessor :timesheet_user
    attr_accessor :filters
    attr_accessor :error
    attr_accessor :valid
    alias :valid? :valid

    @@operators = { "="   => :label_equals,
                    "!"   => :label_not_equals,
                    "o"   => :label_open_issues,
                    "c"   => :label_closed_issues,
                    "!*"  => :label_none,
                    "*"   => :label_all,
                    ">="  => :label_greater_or_equal,
                    "<="  => :label_less_or_equal,
                    "<t+" => :label_in_less_than,
                    ">t+" => :label_in_more_than,
                    "t+"  => :label_in,
                    "t"   => :label_today,
                    "w"   => :label_this_week,
                    ">t-" => :label_less_than_ago,
                    "<t-" => :label_more_than_ago,
                    "t-"  => :label_ago,
                    "~"   => :label_contains,
                    "!~"  => :label_not_contains,
                    ".."  => :label_between}

    cattr_reader :operators
    @@operators_by_filter_type = { :list => [ "=", "!" ],
                                   :list_status => [ "o", "=", "!", "c", "*" ],
                                   :list_optional => [ "=", "!", "!*", "*" ],
                                   :list_member => [ "=" ],
                                   :list_subprojects => [ "*", "!*", "=" ],
                                   :date => [ "<t+", ">t+", "t+", "t", "w", ">t-", "<t-", "t-", ".."],
                                   :date_past => [ ">t-", "<t-", "t-", "t", "w" , ".."],
                                   :string => [ "=", "~", "!", "!~" ],
                                   :text => [  "~", "!~" ],
                                   :integer => [ "=", ">=", "<=", "!*", "*" ] }

    cattr_reader :operators_by_filter_type

    @@available_columns = [
        # QueryColumn.new(:member, :sortable => "#{Member.table_name}.name", :default_order => 'desc'),
        # QueryColumn.new(:project, :sortable => "#{Project.table_name}.name"),
        # QueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position"),
        # QueryColumn.new(:status, :sortable => "#{IssueStatus.table_name}.position"),
        # QueryColumn.new(:priority, :sortable => "#{IssuePriority.table_name}.position", :default_order => 'desc'),
        # QueryColumn.new(:subject, :sortable => "#{Issue.table_name}.subject"),
        # QueryColumn.new(:author),
        # QueryColumn.new(:assigned_to, :sortable => ["#{User.table_name}.lastname", "#{User.table_name}.firstname", "#{User.table_name}.id"]),
        # QueryColumn.new(:updated_on, :sortable => "#{Issue.table_name}.updated_on", :default_order => 'desc'),
        # QueryColumn.new(:category, :sortable => "#{IssueCategory.table_name}.name"),
        # QueryColumn.new(:fixed_version, :sortable => ["#{Version.table_name}.effective_date", "#{Version.table_name}.name"], :default_order => 'desc'),
        # QueryColumn.new(:start_date, :sortable => "#{Issue.table_name}.start_date"),
        # QueryColumn.new(:due_date, :sortable => "#{Issue.table_name}.due_date"),
        # QueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours"),
        # QueryColumn.new(:done_ratio, :sortable => "#{Issue.table_name}.done_ratio"),
        # QueryColumn.new(:created_on, :sortable => "#{Issue.table_name}.created_on", :default_order => 'desc'),
    ]
    cattr_reader :available_columns

    class << self
      def merge_conditions(*conditions)
        segments = []
        conditions.each do |condition|
          unless condition.blank?
            sql = sanitize_sql(condition)
            segments << sql unless sql.blank?
          end
        end

        "(#{segments.join(') AND (')})" unless segments.empty?
      end
    end

    def initialize(attributes = {})
      self.monitoring_projects = []
      projects = attributes[:monitoring_projects].to_a
      #projects += User.current.memberships.collect(&:project).compact.select(&:active?)
      project_tree(projects.uniq) do |project, level|
        name_prefix = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
        self.monitoring_projects << [name_prefix + project.name, project.id.to_s]
      end
      self.monitoring_members = attributes[:monitoring_members].to_a.map{|m| [m[:name],m[:id]]}
      self.timesheet_user = attributes[:timesheet_user]
      self.filters = { 'member_id' => {:operator => "=", :values => [self.timesheet_user.id]}}
      self.error = nil.to_s
      self.valid = true
    end

    def available_filters
      return @available_filters if @available_filters
      trackers = monitoring_projects.blank? ? Tracker.order('position') : rolled_up_trackers
      #trackers = Tracker.find(:all, :order => 'position')
      @available_filters = { "tracker_id" => { :type => :list, :order => 3, :values => trackers.collect{|s| [s.name, s.id.to_s] } },
                             "status_id" => { :type => :list_status, :order => 4, :values => IssueStatus.order('position').collect{|s| [s.name, s.id.to_s] } },
                             "priority_id" => { :type => :list, :order => 5, :values => IssuePriority.all.collect{|s| [s.name, s.id.to_s] } },
                             "subject" => { :type => :text, :order => 6 },
                             "created_on" => { :type => :date_past, :order => 7 },
                             "updated_on" => { :type => :date_past, :order => 8 },
                             "start_date" => { :type => :date, :order => 9 },
                             "due_date" => { :type => :date, :order => 10 },
                             "estimated_hours" => { :type => :integer, :order => 11 },
                             "done_ratio" =>  { :type => :integer, :order => 12 }}
      @available_filters["member_id"] = { :type => :list_member, :order => 1, :values => monitoring_members } unless monitoring_members.blank?
      @available_filters["project_id"] = { :type => :list, :order => 2, :values => monitoring_projects} unless monitoring_projects.blank?
      @available_filters
    end

    def has_filter?(field)
      filters and filters[field]
    end
    def values_for(field)
      has_filter?(field) ? filters[field][:values] : nil
    end
    def operator_for(field)
      has_filter?(field) ? filters[field][:operator] : nil
    end

    def statement
      # filters clauses
      filters_clauses = []
      filters.each_key do |field|
        next if %w(project_id subproject_id member_id).include?(field)
        v = values_for(field).clone
        next unless v and !v.empty?
        operator = operator_for(field)

        # "me" value subsitution
        if %w(assigned_to_id author_id watcher_id).include?(field)
          v.push(User.current.logged? ? User.current.id.to_s : "0") if v.delete("me")
        end

        sql = ''
        if field =~ /^cf_(\d+)$/
          # custom field
          db_table = CustomValue.table_name
          db_field = 'value'
          is_custom_filter = true
          sql << "#{Issue.table_name}.id IN (SELECT #{Issue.table_name}.id FROM #{Issue.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Issue' AND #{db_table}.customized_id=#{Issue.table_name}.id AND #{db_table}.custom_field_id=#{$1} WHERE "
          sql << sql_for_field(field, operator, v, db_table, db_field, true) + ')'
        elsif field == 'watcher_id'
          db_table = Watcher.table_name
          db_field = 'user_id'
          sql << "#{Issue.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.watchable_id FROM #{db_table} WHERE #{db_table}.watchable_type='Issue' AND "
          sql << sql_for_field(field, '=', v, db_table, db_field) + ')'
        else
          # regular field
          db_table = Issue.table_name
          db_field = field
          sql << '(' + sql_for_field(field, operator, v, db_table, db_field) + ')'
        end
        filters_clauses << sql unless sql == '()'

      end if filters and valid?

      filters_clauses.join(' AND ')
    end

    def issues(options)
      issues = Array.new
      return issues if options[:current_time].blank?
      selected_issues = SelectedIssue.where(sql_for_selected_issues(options))
      return issues if selected_issues.blank?

      db_table = Issue.table_name
      issues = Issue.includes(([:status, :project] + (options[:include] || [])).uniq)
      .where(sql_join_clause([sql_for_ids(selected_issues.collect {|si| {:id => si.issue_id}}, db_table ), statement, options[:conditions]]))
      .order(options[:order])
      issues
    rescue ::ActiveRecord::StatementInvalid => e
      raise ::ActiveRecord::StatementInvalid.new(e.message)
    end

    def sort_criteria=(arg)
      c = []
      if arg.is_a?(Hash)
        arg = arg.keys.sort.collect {|k| arg[k]}
      end
      c = arg.select {|k,o| !k.to_s.blank?}.slice(0,3).collect {|k,o| [k.to_s, o == 'desc' ? o : 'asc']}
      @sort_criteria = c
    end

    def sort_criteria
      @sort_criteria.to_a
    end

    # Returns a Hash of columns and the key for sorting
    def sortable_columns
      {'id' => "#{Issue.table_name}.id"}.merge(available_columns.inject({}) {|h, column|
        h[column.name.to_s] = column.sortable
        h
      })
    end

    def add_filter(field, operator, values)
      # values must be an array
      return unless values and values.is_a? Array # and !values.first.empty?
      # check if field is defined as an available filter
      if available_filters.has_key? field
        filter_options = available_filters[field]
        # check if operator is allowed for that filter
        #if @@operators_by_filter_type[filter_options[:type]].include? operator
        #  allowed_values = values & ([""] + (filter_options[:values] || []).collect {|val| val[1]})
        #  filters[field] = {:operator => operator, :values => allowed_values } if (allowed_values.first and !allowed_values.first.empty?) or ["o", "c", "!*", "*", "t"].include? operator
        #end
        filters[field] = {:operator => operator, :values => values }
      end
    end

    def add_short_filter(field, expression)
      return unless expression
      parms = expression.scan(/^(o|c|!\*|!|\*)?(.*)$/).first
      add_filter field, (parms[0] || "="), [parms[1] || ""]
    end

    # Add multiple filters using +add_filter+
    def add_filters(fields, operators, values)
      fields.each do |field|
        add_filter(field, operators[field], values[field])
      end
    end
    def validate
      #validates_presence_of :name, :on => :save
      #validates_length_of :name, :maximum => 255
      self.valid = false if [monitoring_members.to_a.length > 0,
                             monitoring_projects.to_a.length > 0].include? false
      error_messages = []
      if monitoring_members.to_a.length <= 0
        error_messages << l(:member_cannot_empty)
      end
      if monitoring_projects.to_a.length <= 0
        error_messages << l(:project_cannot_empty)
      end

      filters.each_key do |field|
        next if %w(member_id project_id subproject_id).include?(field)
        values = values_for(field).clone
        operator = operator_for(field)
        field_name = l("field_"+field.to_s.gsub(/\_id$/, ""))
        value = nil.to_s
        value_from = nil.to_s
        value_to = nil.to_s

        #check for date range
        if(values != nil && values.is_a?(Array))
          value = values[0].to_s.strip
          if operator == ".." && values.length >= 3
            value = :default_value.to_s
            if values[1].to_s.strip.empty? or values[2].to_s.strip.empty?
              value = nil.to_s
            else
              value_from = values[1]
              value_to = values[2]
            end
          end
        end
        valid_error = []
        unless value_from.empty? or value_to.empty?
          valid_error << (value_from + l(:error_date_invalid)) unless valid_date? value_from
          valid_error << (value_to + l(:error_date_invalid)) unless valid_date? value_to
          if valid_error.blank? && Date.parse(value_from) > Date.parse(value_to)
            valid_error << (value_to + l(:must_be_greater_than) + value_from)
          end
        end
        self.valid = false if [!valid_error.blank?, value.empty?].include? true
        error_messages << (field_name + l(:cannot_empty)) if value.blank? && !["o", "c", "!*", "*", "t", "w"].include?(operator)
        error_messages << (field_name + l(:error_date_invalid) + valid_error.join(',')) unless valid_error.blank?
      end
      error_messages.length == 0 ? self.valid = true : (self.error = error_messages.join("<br/>"))
    end
    private
    def valid_date? value
      Date.parse(value.to_s)
      return true
    rescue
      return false
    end
    def rolled_up_trackers
      db_table = Project.table_name
      @rolled_up_trackers = Tracker.includes(:projects)
      .where(sql_for_ids(db_table, (monitoring_projects).collect {|p| {:id => p[1]}}))
      .order("#{Tracker.table_name}.position").select("DISTINCT #{Tracker.table_name}.*")
    end
    # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
    def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter=false)
      sql = ''
      case operator
        when "="
          sql = "#{db_table}.#{db_field} IN (" + value.collect{|val| "'#{connection.quoted_string(val)}'"}.join(",") + ")"
        when "!"
          sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + value.collect{|val| "'#{connection.quoted_string(val)}'"}.join(",") + "))"
        when "!*"
          sql = "#{db_table}.#{db_field} IS NULL"
          sql << " OR #{db_table}.#{db_field} = ''" if is_custom_filter
        when "*"
          sql = "#{db_table}.#{db_field} IS NOT NULL"
          sql << " AND #{db_table}.#{db_field} <> ''" if is_custom_filter
        when ">="
          sql = "#{db_table}.#{db_field} >= #{value.first.to_f}"
        when "<="
          sql = "#{db_table}.#{db_field} <= #{value.first.to_f}"
        when "o"
          sql = "#{IssueStatus.table_name}.is_closed=#{connection.quoted_false}" if field == "status_id"
        when "c"
          sql = "#{IssueStatus.table_name}.is_closed=#{connection.quoted_true}" if field == "status_id"
        when ">t-"
          sql = date_range_clause(db_table, db_field, - value.first.to_i, 0)
        when "<t-"
          sql = date_range_clause(db_table, db_field, nil, - value.first.to_i)
        when "t-"
          sql = date_range_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
        when ">t+"
          sql = date_range_clause(db_table, db_field, value.first.to_i, nil)
        when "<t+"
          sql = date_range_clause(db_table, db_field, 0, value.first.to_i)
        when "t+"
          sql = date_range_clause(db_table, db_field, value.first.to_i, value.first.to_i)
        when "t"
          sql = date_range_clause(db_table, db_field, 0, 0)
        when "w"
          from = l(:general_first_day_of_week) == '7' ?
              # week starts on sunday
              ((Date.today.cwday == 7) ? Time.now.at_beginning_of_day : Time.now.at_beginning_of_week - 1.day) :
              # week starts on monday (Rails default)
              Time.now.at_beginning_of_week
          sql = "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(from), connection.quoted_date(from + 7.days)]
        when "~"
          sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{connection.quoted_string(value.first.to_s.downcase)}%'"
        when "!~"
          sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{connection.quoted_string(value.first.to_s.downcase)}%'"
        when ".."
          from = nil
          to = nil
          sql = ""
          from = Date.parse(value[1])
          to = Date.parse(value[2])
          sql = value_in_date_range(db_table, db_field, from, to)
      end
      return sql
    end
    def sql_for_selected_issues(options = {})
      db_table = SelectedIssue.table_name
      member_field = 'member_id'
      project_field = 'project_id'

      current_time = options[:current_time]
      mon = return_to_monday(current_time)
      sun = return_to_sun(current_time)
      mon_string = get_sql_time_string(mon)
      sun_string = get_sql_time_string(sun)

      sql_clauses = Array.new
      db_field = "date"
      sql_clauses << "#{db_table}.#{db_field} >= '#{mon_string}'"
      sql_clauses << "#{db_table}.#{db_field} <= '#{sun_string}'"

      db_field = "project_id"
      sql_clauses << sql_for_ids(monitoring_projects.collect {|p| {:id => p[1], :name => p[0]}} ,db_table,db_field)
      if filters.has_key? project_field
        operator = operator_for(project_field)
        value = values_for(project_field)
        sql_clauses << sql_for_field(project_field, operator, value , db_table, db_field)
      end

      db_field = "user_id"
      sql_clauses << sql_for_ids(monitoring_members.collect {|m| {:id => m[1], :name => m[0]}},db_table,db_field)
      if filters.has_key? member_field
        operator = operator_for(member_field)
        value = values_for(member_field)
        sql_clauses << sql_for_field(member_field, operator, value , db_table, db_field)
      end
      sql_clauses.to_a.join(' AND ')
    end
    # Returns a SQL clause for a date or datetime field.
    def date_range_clause(table, field, from, to)
      s = []
      if from
        s << ("#{table}.#{field} > '%s'" % [connection.quoted_date((Date.yesterday + from).to_time.end_of_day)])
      end
      if to
        s << ("#{table}.#{field} <= '%s'" % [connection.quoted_date((Date.today + to).to_time.end_of_day)])
      end
      s.join(' AND ')
    end
    def sql_for_ids(objects, db_table, db_field = "id")
      return nil.to_s unless objects.is_a? Array and objects.length > 0
      sql = "#{db_table}.#{db_field} IN (#{objects.collect {|o| o.is_a?(Hash) ? o[:id] : o.id }.join(',')})"
      return sql
    end
    def sql_join_clause(clauses)
      return nil unless clauses.is_a? Array and clauses.to_a.length > 0 and
          (clauses.compact.reject {|c| c.strip == ''}).length > 0
      (clauses.compact.reject {|c| c.strip == ''}).join(' AND ')
    end
    def value_in_date_range(table, field, from, to)
      sql = ''

      # Use DATE() function of SQL to get only the date part of datetime expression.
      sql << ("DATE(#{table}.#{field}) >= '%s'" % [from])
      sql << ' AND '
      sql << ("DATE(#{table}.#{field}) <= '%s'" % [to])

      return sql
    end
    def connection
      @connection = "connection"
      def @connection.quoted_string(value)
        return value
      end
      def @connection.quoted_true
        "'1'"
      end
      def @connection.quoted_false
        "'0'"
      end
      def @connection.quoted_date(value)
        value.to_s(:db)
      end
      @connection
    end
  end

  def operators_for_select(filter_type)
    TimesheetQuery.operators_by_filter_type[filter_type].collect {|o| [l(TimesheetQuery.operators[o]), o]}
  end

  # Retrieve query from session or build a new query
  def retrieve_query
    store_query_params if is_new_query?
    reset_query_params if reset_new_query?
    @timesheet_query = TimesheetQuery.new({:monitoring_projects => @monitoring_projects,
                                           :monitoring_members => @monitoring_members,
                                           :timesheet_user => @timesheet_user})
    query = restore_query_params
    if query[:fields] and query[:fields].is_a? Array
      query[:fields].each do |field|
        @timesheet_query.add_filter(field,query[:operators][field], query[:values][field])
      end
    else
      @timesheet_query.available_filters.keys.each do |field|
        @timesheet_query.add_short_filter(field, params[field]) if params[field]
      end
    end
    @timesheet_query.validate
  end

  private
  def reset_query_params
    session[:timesheet_query] = {}
  end
  def store_query_params
    session[:timesheet_query] = {} if session[:timesheet_query].nil?
    session[:timesheet_query][:fields] = params[:fields] if params[:fields]
    session[:timesheet_query][:operators] = params[:operators] if params[:operators]
    session[:timesheet_query][:values] = params[:values] if params[:values]
  end
  def restore_query_params
    session[:timesheet_query]
  end
  def is_new_query?
    query = restore_query_params
    return true if query.nil? or !params[:new_timesheet_query].nil?
    return false
  end

  def reset_new_query?
    return true unless params[:reset_query].blank?
    return false
  end

  def query_selected_issues
    retrieve_query
    sort_init(@timesheet_query.sort_criteria.empty? ? [['id', 'desc']] : @timesheet_query.sort_criteria)
    sort_update(@timesheet_query.sortable_columns)
    if(@timesheet_query.valid?)
      @selected_issues = @timesheet_query.issues({:current_time => @current_time,
                                                  :include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                                                  :order => sort_clause})
    end
    @selected_issues ||= []
  end
end
