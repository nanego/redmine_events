require_dependency 'journal'

class Journal
  def send_notification
    if notify? && (Setting.notified_events.include?('issue_updated') ||
        (Setting.notified_events.include?('issue_note_added') && notes.present?) ||
        (Setting.notified_events.include?('issue_status_updated') && new_status.present?) ||
        (Setting.notified_events.include?('issue_priority_updated') && new_value_for('priority_id').present?)
      )
      #our additions
      if notes.present? || details.detect{|d| d.prop_key == "priority_id" && d.value == 6} || details.detect{|d| d.prop_key == "authorized_viewers"}
      #/our additions
        Mailer.deliver_issue_edit(self)
      end
    end
  end
end
