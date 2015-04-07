Deface::Override.new :virtual_path  => "issues/new",
                     :name          => "add_javascript_to_new_issue_form",
                     :insert_after    => "div.wiki",
                     :text          => <<-EOS
<script type="text/javascript">

<% consequence_field_id = Setting['plugin_redmine_events']['consequence_field'] %>

$( "p:contains('Nombre de')" ).css( "display", "none" );

$( "#issue_custom_field_values_<%= consequence_field_id %>" ).change(function() {
  if($( "#issue_custom_field_values_<%= consequence_field_id %>" ).val().indexOf("mort") > -1){
    $( "p:contains('Nombre de')" ).css( "display", "block" );
  }else{
    $( "p:contains('Nombre de')" ).css( "display", "none" );
  }
});

$(function() {
  <% Setting['plugin_redmine_events']['select2_fields'].each do |custom_field_id| %>
    $('#issue_custom_field_values_<%= custom_field_id %>').select2({
      containerCss: {minWidth: '95%'}
    });
  <% end %>

  <% commune_field_id = Setting['plugin_redmine_events']['autocompte_communes_field']
    if commune_field_id.present? %>
      $('#issue_custom_field_values_<%= commune_field_id %>').autocomplete({
        minLength: 2,
        source: "/communes"
      });
  <% end %>
});

</script>

EOS

