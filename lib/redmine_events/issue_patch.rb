require_dependency 'issue'

class Issue < ActiveRecord::Base

  # Copies attributes from another issue, arg can be an id or an Issue
  def copy_from(arg, options={})
    issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
    self.attributes = issue.attributes.dup.except("id", "root_id", "parent_id", "lft", "rgt", "created_on", "updated_on")
    self.custom_field_values = issue.custom_field_values.inject({}) do |h,v|
      unless [4,16,17].include?(v.custom_field_id) # reject some custom fields when converting to flashes / bulletins or points #TODO Make it dynamic with plugin settings
        h[v.custom_field_id] = v.value
      end
      h
    end
    self.status = issue.status
    self.author = User.current
    unless options[:attachments] == false
      self.attachments = issue.attachments.map do |attachement|
        attachement.copy(:container => self)
      end
    end
    @copied_from = issue
    @copy_options = options
    self
  end

end
