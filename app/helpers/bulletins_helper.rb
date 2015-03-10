module BulletinsHelper

  include AttachmentsHelper
  include IssueRelationsHelper

  def column_header(column)
  column.sortable ? sort_header_tag(column.name.to_s, :caption => column.caption,
                                    :default_order => column.default_order) :
      content_tag('th', h(column.caption))
  end


  def issue_list(issues, &block)
    ancestors = []
    issues.each do |issue|
      while (ancestors.any? && !issue.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield issue, ancestors.size
      ancestors << issue unless issue.leaf?
    end
  end

  def column_content(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      value.collect {|v| column_value(column, issue, v)}.compact.join(', ').html_safe
    else
      column_value(column, issue, value)
    end
  end

  def column_value(column, issue, value)
    case column.name
      when :id
        link_to value, bulletin_path(issue)
      when :subject
        link_to value, bulletin_path(issue)
      when :parent
        value ? (value.visible? ? link_to_issue(value, :subject => false) : "##{value.id}") : ''
      when :description
        issue.description? ? content_tag('div', textilizable(issue, :description), :class => "wiki") : ''
      when :done_ratio
        progress_bar(value, :width => '80px')
      when :relations
        other = value.other_issue(issue)
        content_tag('span',
                    (l(value.label_for(issue)) + " " + link_to_issue(other, :subject => false, :tracker => false)).html_safe,
                    :class => value.css_classes_for(issue))
      else
        format_object(value)
    end
  end

  def issues_destroy_confirmation_message(issues)
    issues = [issues] unless issues.is_a?(Array)
    message = l(:text_issues_destroy_confirmation)
    descendant_count = issues.inject(0) {|memo, i| memo += (i.right - i.left - 1)/2}
    if descendant_count > 0
      issues.each do |issue|
        next if issue.root?
        issues.each do |other_issue|
          descendant_count -= 1 if issue.is_descendant_of?(other_issue)
        end
      end
      if descendant_count > 0
        message << "\n" + l(:text_issues_destroy_descendants_confirmation, :count => descendant_count)
      end
    end
    message
  end

  def render_issue_subject_with_tree(issue)
    s = ''
    ancestors = issue.root? ? [] : issue.ancestors.visible.all
    ancestors.each do |ancestor|
      s << '<div>' + content_tag('p', link_to_issue(ancestor, :project => (issue.project_id != ancestor.project_id)))
    end
    s << '<div>'
    subject = h(issue.subject)
    if issue.is_private?
      subject = content_tag('span', l(:field_is_private), :class => 'private') + ' ' + subject
    end
    s << content_tag('h3', subject)
    s << '</div>' * (ancestors.size + 1)
    s.html_safe
  end

  class IssueFieldsRows
    include ActionView::Helpers::TagHelper

    def initialize
      @left = []
      @right = []
    end

    def left(*args)
      args.any? ? @left << cells(*args) : @left
    end

    def right(*args)
      args.any? ? @right << cells(*args) : @right
    end

    def size
      @left.size > @right.size ? @left.size : @right.size
    end

    def to_html
      html = ''.html_safe
      blank = content_tag('th', '') + content_tag('td', '')
      size.times do |i|
        left = @left[i] || blank
        right = @right[i] || blank
        html << content_tag('tr', left + right)
      end
      html
    end

    def cells(label, text, options={})
      content_tag('th', "#{label}:", options) + content_tag('td', text, options)
    end
  end

  def issue_fields_rows
    r = IssueFieldsRows.new
    yield r
    r.to_html
  end

  def render_custom_fields_rows(issue)
    values = issue.visible_custom_field_values
    return if values.empty?
    ordered_values = []
    half = (values.size / 2.0).ceil
    half.times do |i|
      ordered_values << values[i]
      ordered_values << values[i + half]
    end
    s = "<tr>\n"
    n = 0
    ordered_values.compact.each do |value|
      css = "cf_#{value.custom_field.id}"
      s << "</tr>\n<tr>\n" if n > 0 && (n % 2) == 0
      s << "\t<th class=\"#{css}\">#{ h(value.custom_field.name) }:</th><td class=\"#{css}\">#{ h(show_value(value)) }</td>\n"
      n += 1
    end
    s << "</tr>\n"
    s.html_safe
  end

  # Returns a link for adding a new subtask to the given issue
  def link_to_new_subtask(issue)
    attrs = {
        :tracker_id => issue.tracker,
        :parent_issue_id => issue
    }
    link_to(l(:button_add), new_project_issue_path(issue.project, :issue => attrs))
  end

  # Returns the textual representation of a journal details
  # as an array of strings
  def details_to_strings(details, no_html=false, options={})
    options[:only_path] = (options[:only_path] == false ? false : true)
    strings = []
    values_by_field = {}
    details.each do |detail|
      if detail.property == 'cf'
        field = detail.custom_field
        if field && field.multiple?
          values_by_field[field] ||= {:added => [], :deleted => []}
          if detail.old_value
            values_by_field[field][:deleted] << detail.old_value
          end
          if detail.value
            values_by_field[field][:added] << detail.value
          end
          next
        end
      end
      strings << show_detail(detail, no_html, options)
    end
    values_by_field.each do |field, changes|
      detail = JournalDetail.new(:property => 'cf', :prop_key => field.id.to_s)
      detail.instance_variable_set "@custom_field", field
      if changes[:added].any?
        detail.value = changes[:added]
        strings << show_detail(detail, no_html, options)
      elsif changes[:deleted].any?
        detail.old_value = changes[:deleted]
        strings << show_detail(detail, no_html, options)
      end
    end
    strings
  end

  # Returns the textual representation of a single journal detail
  def show_detail(detail, no_html=false, options={})
    multiple = false
    case detail.property
      when 'attr'
        field = detail.prop_key.to_s.gsub(/\_id$/, "")
        label = l(("field_" + field).to_sym)
        case detail.prop_key
          when 'due_date', 'start_date'
            value = format_date(detail.value.to_date) if detail.value
            old_value = format_date(detail.old_value.to_date) if detail.old_value

          when 'project_id', 'status_id', 'tracker_id', 'assigned_to_id',
              'priority_id', 'category_id', 'fixed_version_id'
            value = find_name_by_reflection(field, detail.value)
            old_value = find_name_by_reflection(field, detail.old_value)

          when 'estimated_hours'
            value = "%0.02f" % detail.value.to_f unless detail.value.blank?
            old_value = "%0.02f" % detail.old_value.to_f unless detail.old_value.blank?

          when 'parent_id'
            label = l(:field_parent_issue)
            value = "##{detail.value}" unless detail.value.blank?
            old_value = "##{detail.old_value}" unless detail.old_value.blank?

          when 'is_private'
            value = l(detail.value == "0" ? :general_text_No : :general_text_Yes) unless detail.value.blank?
            old_value = l(detail.old_value == "0" ? :general_text_No : :general_text_Yes) unless detail.old_value.blank?
        end
      when 'cf'
        custom_field = detail.custom_field
        if custom_field
          multiple = custom_field.multiple?
          label = custom_field.name
          value = format_value(detail.value, custom_field) if detail.value
          old_value = format_value(detail.old_value, custom_field) if detail.old_value
        end
      when 'attachment'
        label = l(:label_attachment)
      when 'relation'
        if detail.value && !detail.old_value
          rel_issue = Issue.visible.find_by_id(detail.value)
          value = rel_issue.nil? ? "#{l(:label_issue)} ##{detail.value}" :
              (no_html ? rel_issue : link_to_issue(rel_issue, :only_path => options[:only_path]))
        elsif detail.old_value && !detail.value
          rel_issue = Issue.visible.find_by_id(detail.old_value)
          old_value = rel_issue.nil? ? "#{l(:label_issue)} ##{detail.old_value}" :
              (no_html ? rel_issue : link_to_issue(rel_issue, :only_path => options[:only_path]))
        end
        relation_type = IssueRelation::TYPES[detail.prop_key]
        label = l(relation_type[:name]) if relation_type
    end
    call_hook(:helper_issues_show_detail_after_setting,
              {:detail => detail, :label => label, :value => value, :old_value => old_value })

    label ||= detail.prop_key
    value ||= detail.value
    old_value ||= detail.old_value

    unless no_html
      label = content_tag('strong', label)
      old_value = content_tag("i", h(old_value)) if detail.old_value
      if detail.old_value && detail.value.blank? && detail.property != 'relation'
        old_value = content_tag("del", old_value)
      end
      if detail.property == 'attachment' && !value.blank? && atta = Attachment.find_by_id(detail.prop_key)
        # Link to the attachment if it has not been removed
        value = link_to_attachment(atta, :download => true, :only_path => options[:only_path])
        if options[:only_path] != false && atta.is_text?
          value += link_to(
              image_tag('magnifier.png'),
              :controller => 'attachments', :action => 'show',
              :id => atta, :filename => atta.filename
          )
        end
      else
        value = content_tag("i", h(value)) if value
      end
    end

    if detail.property == 'attr' && detail.prop_key == 'description'
      s = l(:text_journal_changed_no_detail, :label => label)
      unless no_html
        diff_link = link_to 'diff',
                            {:controller => 'journals', :action => 'diff', :id => detail.journal_id,
                             :detail_id => detail.id, :only_path => options[:only_path]},
                            :title => l(:label_view_diff)
        s << " (#{ diff_link })"
      end
      s.html_safe
    elsif detail.value.present?
      case detail.property
        when 'attr', 'cf'
          if detail.old_value.present?
            l(:text_journal_changed, :label => label, :old => old_value, :new => value).html_safe
          elsif multiple
            l(:text_journal_added, :label => label, :value => value).html_safe
          else
            l(:text_journal_set_to, :label => label, :value => value).html_safe
          end
        when 'attachment', 'relation'
          l(:text_journal_added, :label => label, :value => value).html_safe
      end
    else
      l(:text_journal_deleted, :label => label, :old => old_value).html_safe
    end
  end

  # Find the name of an associated record stored in the field attribute
  def find_name_by_reflection(field, id)
    unless id.present?
      return nil
    end
    association = Issue.reflect_on_association(field.to_sym)
    if association
      record = association.class_name.constantize.find_by_id(id)
      if record
        record.name.force_encoding('UTF-8') if record.name.respond_to?(:force_encoding)
        return record.name
      end
    end
  end

  # Return a string used to display a custom value
  def show_value(custom_value, html=true)
    format_object(custom_value, html)
  end


end
