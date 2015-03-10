require 'redmine_events/hooks'

Rails.application.config.to_prepare do
  require_dependency 'redmine_events/issues_controller_patch'
end


Redmine::Plugin.register :redmine_events do
  name 'Redmine Events plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  permission :bulletins, { :bulletins => [:index] }, :public => true
  permission :flashs, { :issues => [:flashs] }, :public => true
  menu :project_menu, :flashs, {controller: 'issues', action: 'flashs'}, :caption => :label_flashs, :param => :project_id
  menu :project_menu, :bulletins, {controller: 'bulletins', action: 'index'}, :caption => :label_bulletins, :param => :project_id
end
