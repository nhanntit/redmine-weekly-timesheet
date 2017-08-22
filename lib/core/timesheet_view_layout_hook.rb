class TimesheetViewLayoutHook < Redmine::Hook::ViewListener
  unloadable

  # List of controllers' names supported by plugin.
  @@supported_controllers = %w(TimesheetController ContextMenuTSS IssuesController VersionsController MyController)

  # Overridden Redmine hook.
  # Appends content to the HTML head of the base layout (such as: javascript, css styles, etc.).
  def view_layouts_base_html_head(context = {})
    output = ''

    @controller = context[:controller]
    return output if !@controller
    return output if @@supported_controllers.include?(@controller.class.name) == false

    #include javascript/css to the head tag here
    output << javascript_include_tag('timesheet', :plugin => 'weekly_timesheet')
    output << stylesheet_link_tag('timesheet', :plugin => 'weekly_timesheet')

    return output
  rescue Exception => exc
    puts exc
    puts exc.backtrace
    return ''
  end

  # add a form into page view for choosing week when add an issue to my timesheet
  def view_layouts_base_body_bottom(context = {})
    output = ''

    @controller = context[:controller]
    return output if !@controller
    return output if @@supported_controllers.include?(@controller.class.name) == false

    # all controller call "issues_context_menu_path" must be in @@supported_controllers
    output << @controller.send(:render_to_string, {:partial => 'timesheet/add_in_timesheet_popup.html.erb'})

    return output
  rescue Exception => exc
    puts exc
    puts exc.backtrace
    return ''
  end

end