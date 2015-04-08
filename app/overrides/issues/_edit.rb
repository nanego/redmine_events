Deface::Override.new :virtual_path  => "issues/_edit",
                     :name          => "hide-notes-field",
                     :remove       => 'fieldset:contains("l(:field_notes)")'

Deface::Override.new :virtual_path  => "issues/_edit",
    :name          => "hide-attachments-field",
    :remove       => 'fieldset:contains("l(:label_attachment_plural)")'
