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

  # Safely sets attributes
  # Should be called from controllers instead of #attributes=
  # attr_accessible is too rough because we still want things like
  # Issue.new(:project => foo) to work
  def safe_attributes=(attrs, user=User.current)
    return unless attrs.is_a?(Hash)

    attrs = attrs.deep_dup

    # Project and Tracker must be set before since new_statuses_allowed_to depends on it.
    if (p = attrs.delete('project_id')) && safe_attribute?('project_id')
      if allowed_target_projects(user).where(:id => p.to_i).exists?
        self.project_id = p
      end
    end

    if (t = attrs.delete('tracker_id')) && safe_attribute?('tracker_id')
      self.tracker_id = t
    end
    if project
      # Set the default tracker to accept custom field values
      # even if tracker is not specified
      self.tracker ||= project.trackers.first
    end

    if (s = attrs.delete('status_id')) && safe_attribute?('status_id')
      if new_statuses_allowed_to(user).collect(&:id).include?(s.to_i)
        self.status_id = s
      end
    end

    attrs = delete_unsafe_attributes(attrs, user)
    return if attrs.empty?

    if attrs['parent_issue_id'].present?
      s = attrs['parent_issue_id'].to_s
      unless (m = s.match(%r{\A#?(\d+)\z})) && (m[1] == parent_id.to_s || Issue.visible(user).exists?(m[1]))
        @invalid_parent_issue_id = attrs.delete('parent_issue_id')
      end
    end

    if attrs['custom_field_values'].present?
      editable_custom_field_ids = editable_custom_field_values(user).map {|v| v.custom_field_id.to_s}

      ###############
      ## Custom START
      editable_custom_field_ids |= editable_custom_field_values(user).map {|v| v.custom_field_id.to_s + '-comment'}
      ## Custom END
      ###############

      attrs['custom_field_values'].select! {|k, v| editable_custom_field_ids.include?(k.to_s)}
    end

    if attrs['custom_fields'].present?
      editable_custom_field_ids = editable_custom_field_values(user).map {|v| v.custom_field_id.to_s}
      attrs['custom_fields'].select! {|c| editable_custom_field_ids.include?(c['id'].to_s)}
    end

    # mass-assignment security bypass
    assign_attributes attrs, :without_protection => true
  end

end
