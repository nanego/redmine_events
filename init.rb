Redmine::Plugin.register :redmine_events do
  name 'Redmine Events plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  menu :project_menu, :bulletins, { :controller => 'issues', :action => 'index' }, :caption => :label_bulletins
end
