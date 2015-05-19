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
<% if @issue.tracker.name =~ /flash/i  %>
  <%= link_to l(:send_flash), '#', :class => 'icon icon-report', :onclick => 'showModal("ajax-modal", "500px");$("#button_apply_projects").focus();' %>
<% else %>
  <% if @issue.tracker.name =~ /point/i  %>
    <%= link_to 'Emettre le point de situation', '#', :class => 'icon icon-report', :onclick => 'showModal("ajax-modal", "500px");$("#button_apply_projects").focus();' %>
  <% end %>
<% end %>
<script type="text/javascript">
  $(document).ready(function(){
    $('#ajax-modal').html('<%= escape_javascript(render :partial => 'issues/modal_send_to_mailing_list') %>');
  });
</script>
EOS

Deface::Override.new :virtual_path  => "bulletins/show",
                     :name          => "add_send_bulletin_link",
                     :insert_top    => "div.contextual",
                     :text          => <<-EOS
<%= link_to 'Emettre le bulletin', '#', :class => 'icon icon-report', :onclick => 'showModal("ajax-modal", "500px");$("#button_apply_projects").focus();' %>
<script type="text/javascript">
  $(document).ready(function(){
    $('#ajax-modal').html('<%= escape_javascript(render :partial => 'issues/modal_send_to_mailing_list') %>');
  });
</script>
EOS


