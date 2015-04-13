Deface::Override.new :virtual_path  => "issues/_form_custom_fields",
                       :name          => "insert-wiki-toolbars",
                       :insert_after  => 'div.splitcontent',
                       :text          => <<-EOS
<% Setting['plugin_redmine_events']['wiki_toolbar_fields'].each do |custom_field_id| %>
  <%= wikitoolbar_for 'issue_custom_field_values_'+custom_field_id.to_s %>
<% end %>
EOS
