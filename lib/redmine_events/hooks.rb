module RedmineEvents
  class Hooks < Redmine::Hook::ViewListener
    #adds our css on each page
    def view_layouts_base_html_head(context)
      stylesheet_link_tag("redmine_events", :plugin => "redmine_events")
    end
  end
end
