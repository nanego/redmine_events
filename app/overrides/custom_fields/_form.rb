#encoding: utf-8
Deface::Override.new :virtual_path  => "custom_fields/_form",
                     :name          => "add-commentable-checkbox-to-custom-field",
                     :insert_after => 'erb[loud]:contains("render_custom_field_format_partial")',
                     :text          => <<-EOS
<p><%= f.check_box :commentable %></p>
EOS
