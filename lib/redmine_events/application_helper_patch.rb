require_dependency 'application_helper'

module ApplicationHelper

  # DO NOT render the project quick-jump box, except when running core tests
  def render_project_jump_box
    return
  end unless Rails.env.test?

  unless instance_methods.include?(:format_object_with_event)
    def format_object_with_event(object, html=true, &block)
      if (object.class.name == 'CustomValue' || object.class.name == 'CustomFieldValue') && object.custom_field
        f = object.custom_field.format.formatted_custom_value(self, object, html)
        if f.nil? || f.is_a?(String)
          textilizable(object.value)
        else
          format_object_without_event(object, html, &block)
        end
      else
        format_object_without_event(object, html, &block)
      end
    end
    alias_method_chain :format_object, :event
  end

end
