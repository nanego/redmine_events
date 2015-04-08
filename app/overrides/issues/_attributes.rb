Deface::Override.new :virtual_path  => "issues/_attributes",
                     :name          => "hide-status-field",
                     :replace       => 'p:contains("status_id")',
                     :text          => <<-EOS
<% if @issue.tracker.name =~ /fiche/i || @issue.tracker.blank? %>
  <%= f.hidden_field :status_id %>
<% else %>
  <p><%= f.select :status_id, (@allowed_statuses.collect {|p| [p.name, p.id]}), {:required => true} %></p>
<% end %>
EOS

Deface::Override.new :virtual_path  => "issues/_attributes",
                     :name          => "hide-status-label",
                     :replace       => 'p:contains("h(@issue.status.name)")',
                     :text          => <<-EOS
<% if @issue.tracker.name =~ /fiche/i || @issue.tracker.blank? %>
<% else %>
  <p><label><%= l(:field_status) %></label> <%= h(@issue.status.name) %></p>
<% end %>
EOS
