Deface::Override.new :virtual_path  => "points/show",
                     :name          => "add_send_point_link",
                     :insert_top    => "div.contextual",
                     :text          => <<-EOS
<%= link_to 'Emettre le point de situation', '#', :class => 'icon icon-report', :onclick => 'showModal("ajax-modal", "500px");$("#button_apply_projects").focus();' %>
<script type="text/javascript">
  $(document).ready(function(){
    $('#ajax-modal').html('<%= escape_javascript(render :partial => 'issues/modal_send_to_mailing_list') %>');
  });
</script>
EOS

Deface::Override.new :virtual_path  => "points/show",
                     :name          => "replace_pdf_export_in_show_points",
                     :replace       => 'erb[loud]:contains("f.link_to \'PDF\'")',
                     :text          => <<-EOS
<%= link_to 'PDF', description_issue_path(@issue, format: :pdf), target: "_blank" %>
EOS

