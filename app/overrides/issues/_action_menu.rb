Deface::Override.new :virtual_path  => "issues/_action_menu",
                     :name          => "add_generate_flash_issue_to_event",
                     :insert_top    => "div.contextual",
                     :text          => <<-EOS
<%= link_to l(:button_generate_flash), issue_create_flash_path(@issue), :class => 'icon icon-report' if @issue.tracker==Tracker.find_by_name('Fiche événement') %>
EOS

Deface::Override.new :virtual_path  => "issues/_action_menu",
                     :name          => "add_get_pdf_to_flashes",
                     :insert_top    => "div.contextual",
                     :text          => <<-EOS
<% if @issue.tracker.name =~ /flash/i %>
  <%= link_to l(:send_flash), description_issue_path(@issue, format: :html), :class => 'icon icon-report' %>
<% end %>
EOS
