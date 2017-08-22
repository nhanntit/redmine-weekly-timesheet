class SelectedIssue < ActiveRecord::Base
  unloadable

  belongs_to :issue
  belongs_to :user
  belongs_to :project

end
