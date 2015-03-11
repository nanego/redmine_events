Deface::Override.new :virtual_path  => "issues/index",
                     :name          => "update_page_title_according_to_current_action",
                     :replace    => "h2",
                     :text          => <<-EOS
<h2><%= action_name == 'flashs' ? 'Flashs' : l(:label_issue_plural) %></h2>
EOS


Deface::Override.new :virtual_path  => "issues/index",
                     :name          => "update_selected_tab_in_project_menu",
                     :replace    => "h2",
                     :text          => <<-EOS
<h2><%= action_name == 'flashs' ? 'Flashs' : l(:label_issue_plural) %></h2>
EOS
