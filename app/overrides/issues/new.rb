Deface::Override.new :virtual_path  => "issues/new",
                     :name          => "add_javascript_to_new_issue_form",
                     :insert_after    => "div.wiki",
                     :text          => <<-EOS
<script>

$( "p:contains('Nombre de')" ).css( "display", "none" );

$( "#issue_custom_field_values_4" ).change(function() {
  if($( "#issue_custom_field_values_4" ).val().indexOf("mort") > -1){
    $( "p:contains('Nombre de')" ).css( "display", "block" );
  }else{
    $( "p:contains('Nombre de')" ).css( "display", "none" );
  }
});

</script>

EOS
