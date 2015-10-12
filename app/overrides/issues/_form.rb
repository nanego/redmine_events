unless Rails.env.test?
  Deface::Override.new :virtual_path  => "issues/_form",
                       :name          => "hide-tracker-field",
                       :replace       => 'p:contains("tracker_id")',
                       :text          => <<-EOS
  <p style="display:none;"> <%= f.select :tracker_id, @issue.project.trackers.collect {|t| [t.name, t.id]}, {:required => true} %>  </p>
  EOS

  Deface::Override.new :virtual_path  => "issues/_form",
                       :name          => "hide-description-field",
                       :replace       => 'erb[silent]:contains("if @issue.safe_attribute? \'description\'")',
                       :text          => <<-EOS
  <% if (@issue.safe_attribute? 'description') && @issue.tracker.name.include?('Flash')  %>
  EOS

  Deface::Override.new :virtual_path  => "issues/_form",
                       :name          => "hide-private-field",
                       :replace       => 'erb[loud]:contains("f.check_box :is_private")',
                       :text          => <<-EOS
  <%= f.hidden_field :is_private  %>
  EOS

  Deface::Override.new :virtual_path  => "issues/_form",
                       :name          => "hide-private-label",
                       :remove       => 'label#issue_is_private_label'

  # Always show issue description in forms
  Deface::Override.new :virtual_path => "issues/_form",
                       :name => "remove_link_to_switch_description_on",
                       :remove => 'erb[loud]:contains("link_to_function image_tag")'
  Deface::Override.new :virtual_path => "issues/_form",
                       :name => "show_description_text_area",
                       :replace => 'erb[loud]:contains(\':id => "issue_description_and_toolbar"\')',
                       :text => "<%= content_tag 'span', :id => \"issue_description_and_toolbar\" do %>"
end
