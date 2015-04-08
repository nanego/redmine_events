Deface::Override.new :virtual_path  => "issues/new",
                     :name          => "add_javascript_to_new_issue_form",
                     :insert_after  => "div.wiki",
                     :partial       => "issues/add_script_to_form"
