require_dependency 'custom_fields_helper'
module CustomFieldsHelper

  # Return a string used to display a custom value
  def show_value(custom_value, html=true)
    if custom_value.comment.present? && (!custom_value.comment.kind_of?(Enumerable) || custom_value.comment.any?{|c|c.present?})
      format_object(custom_value, html).html_safe + ' (' + custom_value.comment + ')'
    else
      format_object(custom_value, html)
    end

  end

end
