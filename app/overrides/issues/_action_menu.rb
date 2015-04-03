Deface::Override.new :virtual_path  => "issues/_action_menu",
                     :name          => "add_generate_flash_issue_to_event",
                     :insert_top    => "div.contextual",
                     :text          => <<-EOS
<%= link_to l(:button_generate_flash), issue_create_flash_path(@issue), :class => 'icon icon-report' if @issue.tracker==Tracker.find_by_name('Fiche événement') %>
EOS

Deface::Override.new :virtual_path  => "issues/_action_menu",
                     :name          => "add_get_pdf_to_flashes",
                     :insert_after => "div.contextual",
                     :text          => <<-EOS
<% if @issue.tracker!=Tracker.find_by_name('Fiche événement') %>
  <%= link_to image_tag('icon_PDF.png', :plugin => :redmine_events), description_issue_path(@issue, format: :pdf), style:'float:left;margin-top:-3px;', 'download'=>"Flash_"+@issue.id.to_s+".pdf" %>
  <%= link_to l(:download_pdf), description_issue_path(@issue, format: :pdf), style:'float:left;padding:6px 10px 0 8px', 'download'=>"Flash_"+@issue.id.to_s+".pdf" %>
<% end %>
EOS
