require_dependency 'application_helper'

module ApplicationHelper

  # DO NOT render the project quick-jump box
  def render_project_jump_box
    return
  end

  # Helper that formats object for html or text rendering
  def format_object(object, html=true, &block)
    if block_given?
      object = yield object
    end
    case object.class.name
      when 'Array'
        object.map {|o| format_object(o, html)}.join(', ').html_safe
      when 'Time'
        format_time(object)
      when 'Date'
        format_date(object)
      when 'Fixnum'
        object.to_s
      when 'Float'
        sprintf "%.2f", object
      when 'User'
        html ? link_to_user(object) : object.to_s
      when 'Project'
        html ? link_to_project(object) : object.to_s
      when 'Version'
        html ? link_to_version(object) : object.to_s
      when 'TrueClass'
        l(:general_text_Yes)
      when 'FalseClass'
        l(:general_text_No)
      when 'Issue'
        object.visible? && html ? link_to_issue(object) : "##{object.id}"
      when 'CustomValue', 'CustomFieldValue'
        if object.custom_field
          f = object.custom_field.format.formatted_custom_value(self, object, html)
          if f.nil? || f.is_a?(String)
            ## CUSTOM PATCH START
            textilizable(object.value)
            ## CUSTOM PATCH STOP
          else
            format_object(f, html, &block)
          end
        else
          object.value.to_s
        end
      else
        html ? h(object) : object.to_s
    end
  end

end
