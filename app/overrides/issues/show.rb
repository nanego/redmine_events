Deface::Override.new :virtual_path  => "issues/show",
                     :name          => "hide_all_fields_except_status",
                     :replace       => "table.attributes",
                     :text          => <<-EOS
<% if @issue.tracker.name =~ /flash/i %>
  <table class="attributes">
    <%= issue_fields_rows do |rows|
      rows.left l(:field_status), h(@issue.status.name), :class => 'status'
    end %>
  </table>
<% else %>
  <% if @issue.tracker.name =~ /Fiche/i %>
    <table class="attributes">
    <%= issue_fields_rows do |rows|
      #rows.left l(:field_status), h(@issue.status.name), :class => 'status'
      rows.left l(:field_priority), h(@issue.priority.name), :class => 'priority'

      unless @issue.disabled_core_fields.include?('assigned_to_id')
        rows.left l(:field_assigned_to), avatar(@issue.assigned_to, :size => "14").to_s.html_safe + (@issue.assigned_to ? link_to_user(@issue.assigned_to) : "-"), :class => 'assigned-to'
      end
      unless @issue.disabled_core_fields.include?('category_id')
        rows.left l(:field_category), h(@issue.category ? @issue.category.name : "-"), :class => 'category'
      end
      unless @issue.disabled_core_fields.include?('fixed_version_id')
        rows.left l(:field_fixed_version), (@issue.fixed_version ? link_to_version(@issue.fixed_version) : "-"), :class => 'fixed-version'
      end

      unless @issue.disabled_core_fields.include?('start_date')
        rows.right l(:field_start_date), format_date(@issue.start_date), :class => 'start-date'
      end
      unless @issue.disabled_core_fields.include?('due_date')
        rows.right l(:field_due_date), format_date(@issue.due_date), :class => 'due-date'
      end
      unless @issue.disabled_core_fields.include?('estimated_hours')
        unless @issue.estimated_hours.nil?
          rows.right l(:field_estimated_hours), l_hours(@issue.estimated_hours), :class => 'estimated-hours'
        end
      end
      if User.current.allowed_to?(:view_time_entries, @project)
        rows.right l(:label_spent_time), (@issue.total_spent_hours > 0 ? link_to(l_hours(@issue.total_spent_hours), issue_time_entries_path(@issue)) : "-"), :class => 'spent-time'
      end
    end %>
    <%= render_custom_fields_rows(@issue) %>
    <%= call_hook(:view_issues_show_details_bottom, :issue => @issue) %>
    </table>
  <% else %>
    <table class="attributes">
    <%= issue_fields_rows do |rows|
      rows.left l(:field_status), h(@issue.status.name), :class => 'status'
      rows.left l(:field_priority), h(@issue.priority.name), :class => 'priority'

      unless @issue.disabled_core_fields.include?('assigned_to_id')
        rows.left l(:field_assigned_to), avatar(@issue.assigned_to, :size => "14").to_s.html_safe + (@issue.assigned_to ? link_to_user(@issue.assigned_to) : "-"), :class => 'assigned-to'
      end
      unless @issue.disabled_core_fields.include?('category_id')
        rows.left l(:field_category), h(@issue.category ? @issue.category.name : "-"), :class => 'category'
      end
      unless @issue.disabled_core_fields.include?('fixed_version_id')
        rows.left l(:field_fixed_version), (@issue.fixed_version ? link_to_version(@issue.fixed_version) : "-"), :class => 'fixed-version'
      end

      unless @issue.disabled_core_fields.include?('start_date')
        rows.right l(:field_start_date), format_date(@issue.start_date), :class => 'start-date'
      end
      unless @issue.disabled_core_fields.include?('due_date')
        rows.right l(:field_due_date), format_date(@issue.due_date), :class => 'due-date'
      end
      unless @issue.disabled_core_fields.include?('estimated_hours')
        unless @issue.estimated_hours.nil?
          rows.right l(:field_estimated_hours), l_hours(@issue.estimated_hours), :class => 'estimated-hours'
        end
      end
      if User.current.allowed_to?(:view_time_entries, @project)
        rows.right l(:label_spent_time), (@issue.total_spent_hours > 0 ? link_to(l_hours(@issue.total_spent_hours), issue_time_entries_path(@issue)) : "-"), :class => 'spent-time'
      end
    end %>
    <%= render_custom_fields_rows(@issue) %>
    <%= call_hook(:view_issues_show_details_bottom, :issue => @issue) %>
    </table>
  <% end %>
<% end %>
EOS

Deface::Override.new :virtual_path  => "issues/show",
                     :name          => "hide_atom_export",
                     :remove        => 'erb[loud]:contains("f.link_to \'Atom\'")'

Deface::Override.new :virtual_path  => "issues/show",
                     :name          => "hide_first_description_separator",
                     :surround      => 'hr:first',
                     :text          => "<div style='display:<%= (@issue.present? && @issue.tracker.name != 'Fiche événement') ? 'block':'none' %>;'><%= render_original %></div>"
Deface::Override.new :virtual_path  => "issues/show",
                     :name          => "hide_description",
                     :surround        => 'div.description',
                     :text          => "<div style='display:<%= (@issue.present? && @issue.tracker.name != 'Fiche événement') ? 'block':'none' %>;'><%= render_original %></div>"

Deface::Override.new :virtual_path  => "issues/show",
                     :name          => "replace_pdf_export",
                     :replace       => 'erb[loud]:contains("f.link_to \'PDF\'")',
                     :text          => <<EOS
<% if @issue.tracker.name =~ /flash/i %>
  <%= link_to 'PDF', description_issue_path(@issue, format: :html) %>
<% else %>
  <%= f.link_to 'PDF' %>
<% end %>
EOS

Deface::Override.new :virtual_path  => "issues/show",
                     :name          => "add_javascript_to_edit_issue_form",
                     :insert_after  => 'erb[loud]:contains("context_menu")',
                     :partial       => "issues/add_script_to_form"

