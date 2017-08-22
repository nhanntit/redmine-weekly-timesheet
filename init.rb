require 'redmine'
# view
require_dependency 'core/timesheet_view_layout_hook'
require_dependency 'core/timesheet_hooks'


ActionDispatch::Callbacks.to_prepare do
  ActionView::Base.send(:include, TimesheetHelper)
end


Redmine::Plugin.register :weekly_timesheet do
  name 'Weekly Timesheet plugin'
  author 'Nhan Nguyen'
  description 'This is a plugin for Redmine that users can make weekly working plan, track and log spent time easily'
  version '0.8'
  url 'https://github.com/path/to/plugin'
  author_url 'http://nhanntit.com.vn/about'

  menu :top_menu, :Timesheet, { :controller => 'timesheet', :action => 'index' }, :caption => :label_menu_timesheet, :html => {:class=>"icon icon-time"}, :before => :projects

  permission :show_members_timesheet, {:timesheet => [:show_member_timesheet]}, :require => :member

end
