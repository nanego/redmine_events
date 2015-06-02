Deface::Override.new :virtual_path  => "bulletins/show",
                     :name          => "replace_bulletin_pdf_export",
                     :replace       => 'erb[loud]:contains("f.link_to \'PDF\'")',
                     :text          => <<EOS
  <%= link_to 'PDF', description_issue_path(@issue, format: :pdf), target: "_blank" %>
EOS
