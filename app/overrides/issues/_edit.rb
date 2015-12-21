unless Rails.env.test?
  Deface::Override.new :virtual_path  => "issues/_edit",
                       :name          => "hide-notes-field",
                       :remove       => 'fieldset:contains("l(:field_notes)")'
  Deface::Override.new :virtual_path  => "issues/_edit",
      :name          => "hide-attachments-field",
      :remove       => 'fieldset:contains("l(:label_attachment_plural)")'
end

Deface::Override.new :virtual_path  => "issues/_edit",
                     :name          => "remove_preview_link_from_issue_edit_form",
                     :remove       => 'erb[loud]:contains("preview_link")'
