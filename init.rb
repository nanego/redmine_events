require 'redmine_events/hooks'

Rails.application.config.to_prepare do
  require_dependency 'redmine_events/issues_controller_patch'
  require_dependency 'redmine_events/application_helper_patch'
  require_dependency 'redmine_events/queries_helper_patch' unless Rails.env.test?
  require_dependency 'redmine_events/less_mail_patch' unless Rails.env.test?
  require_dependency 'redmine_events/issue_query_patch' unless Rails.env.test?
  require_dependency 'redmine_events/issues_helper_patch'
  require_dependency 'redmine_events/issue_patch'
  require_dependency 'redmine_events/custom_field_value_patch'
  require_dependency 'redmine_events/mailer_patch'
  require_dependency 'redmine_events/acts_as_customizable_patch'
end

Redmine::Plugin.register :redmine_events do
  name 'Redmine Events plugin'
  author 'Vincent ROBERT'
  description 'This is a private plugin for Redmine which allow us to create and organize event notifications instead of issues'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  requires_redmine_plugin :redmine_base_select2, :version_or_higher => '0.0.1'
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
  permission :points, { :points => [:index] }, :public => true
  permission :bulletins, { :bulletins => [:index] }, :public => true
  permission :flashs, { :issues => [:flashs] }, :public => true
  menu :project_menu, :flashs, {controller: 'issues', action: 'flashs'}, :caption => :label_flashs, :param => :project_id
  menu :project_menu, :bulletins, {controller: 'bulletins', action: 'index'}, :caption => :label_bulletins, :param => :project_id
  menu :project_menu, :points, {controller: 'points', action: 'index'}, :caption => :label_points, :param => :project_id

  settings :default => { 'select2_fields' => [], 'commune_field' => nil},
           :partial => 'settings/redmine_plugin_events_settings'

  unless Rails.env.test?
    Redmine::MenuManager.map :top_menu do |menu|
      menu.delete :help
      menu.delete :administration
      menu.delete :projects
      menu.delete :my_page
      menu.delete :home
      menu.push :issues, { :controller => 'issues', :project_id => 'cmvoa' }, :caption => :label_issue_plural,
                :if => Proc.new{ User.current.logged? && User.current.allowed_to?(:view_issues, nil, :global => true) }
      menu.push :administration, { :controller => 'settings' },
                :if => Proc.new { User.current.admin? }, :last => true
    end
=begin
    Redmine::MenuManager.map :project_menu do |menu|
      #menu.delete :settings
      menu.delete :new_issue
      menu.push :new_issue, { :controller => 'issues', :action => 'new' }, :param => :project_id, :caption => 'Nouvel événement',
                :html => { :accesskey => Redmine::AccessKeys.key_for(:new_issue) }, :after => :activity
    end
=end
  end
end
