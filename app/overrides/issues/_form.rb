Deface::Override.new :virtual_path  => "issues/_form",
                     :name          => "hide-tracker-field",
                     :replace       => 'p:contains("tracker_id")',
                     :text          => <<-EOS
<p style="display:none;"> <%= f.select :tracker_id, @issue.project.trackers.collect {|t| [t.name, t.id]}, {:required => true} %>  </p>
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
