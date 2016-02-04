Deface::Override.new :virtual_path  => "issues/_form_custom_fields",
                       :name          => "insert-wiki-toolbars",
                       :insert_after  => 'div.splitcontent',
                       :text          => <<-EOS
<% Setting['plugin_redmine_events']['wiki_toolbar_fields'].each do |custom_field_id| %>
  <%= wikitoolbar_for 'issue_custom_field_values_'+custom_field_id.to_s %>
<% end if Setting['plugin_redmine_events']['wiki_toolbar_fields'].present? %>
EOS

Deface::Override.new :virtual_path  => "issues/_form_custom_fields",
                     :name          => "add-comment-to-custom-fields",
                     :insert_after  => 'erb[loud]:contains("custom_field_tag_with_label")',
                     :text          => <<-EOS
<%= if value.custom_field.commentable?
  self.text_field_tag("issue[custom_field_values]["+value.custom_field.id.to_s+"-comment]", value.comment, {:id => "issue_custom_field_comments_"+value.custom_field.id.to_s})
end %>
EOS
