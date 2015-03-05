Redmine::Plugin.register :redmine_events do
  name 'Redmine Events plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  permission :bulletins, { :bulletins => [:index] }, :public => true
  menu :project_menu, :bulletins, {controller: 'bulletins', action: 'index'}, :caption => :label_bulletins
end
