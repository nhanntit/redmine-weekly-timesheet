# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get '/timesheet', :to => 'timesheet#index'
get '/timesheet/index', :to => 'timesheet#index'
post '/timesheet/add', :to => 'timesheet#add'
post '/timesheet/remove', :to => 'timesheet#remove'
post '/timesheet/remove_cm', :to => 'timesheet#remove_cm'
post '/timesheet/add_in_timesheet', :to => 'timesheet#add_in_timesheet'
get '/timesheet/select_week', :to => 'timesheet#select_week'
post '/timesheet/load_user_timesheet', :to => 'timesheet#load_user_timesheet'
get '/timesheet/goto', :to => 'timesheet#goto'
post '/timesheet/copyfrom', :to => 'timesheet#copyfrom'
post '/timesheet/copyto', :to => 'timesheet#copyto'
get '/timesheet/changemode', :to => 'timesheet#changemode'
get '/timesheet/export_to_csv', :to => 'timesheet#export_to_csv'
get '/timesheet/ajax_load_form_log_time', :to => 'timesheet#ajax_load_form_log_time'
post '/timesheet/logtime', :to => 'timesheet#logtime'
post '/timesheet/plantime', :to => 'timesheet#plantime'
get '/context_menu_tss/issues', :to => 'context_menu_tss#issues'
