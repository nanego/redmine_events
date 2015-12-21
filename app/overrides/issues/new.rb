Deface::Override.new :virtual_path  => "issues/new",
                     :name          => "add_javascript_to_new_issue_form",
                     :insert_after  => "div.wiki",
                     :partial       => "issues/add_script_to_form"

Deface::Override.new :virtual_path  => "issues/new",
                     :name          => "remove_preview_link_from_issue_form",
                     :remove       => 'erb[loud]:contains("preview_link")'
