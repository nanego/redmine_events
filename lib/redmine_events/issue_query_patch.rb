require_dependency 'issue_query'
class IssueQuery < Query
  class_attribute :context
  def default_event_columns_names
    @default_columns_names ||=  [:id, :subject, :cf_9, :cf_1, :updated_on]  # domaines, departement
  end

  def default_flash_columns_names
    @default_columns_names ||=  [:id, :status, :subject, :cf_1, :updated_on]
  end

  def default_bulletins_columns_names
    @default_columns_names ||=  [:id, :status, :subject, :updated_on]
  end

  def columns
    # preserve the column_names order
    case
      when filters.include_hash?({"tracker_id"=>{:operator=>"=", :values=>["#{Tracker.find_by_name("Flash").id}"]}})
        _default_columns_names = default_flash_columns_names
      when filters.include_hash?({"tracker_id"=>{:operator=>"=", :values=>["#{Tracker.find_by_name("Fiche événement").id}"]}})
        _default_columns_names = default_event_columns_names
      when filters.include_hash?({"tracker_id"=>{:operator=>"=", :values=>["#{Tracker.where("trackers.name like '%Bulletin%'").first.id}"]}})
        _default_columns_names = default_bulletins_columns_names
      when filters.include_hash?({"tracker_id"=>{:operator=>"=", :values=>["#{Tracker.where("trackers.name like '%Point%'").first.id}"]}})
        _default_columns_names = default_bulletins_columns_names
      else
        _default_columns_names = default_columns_names
    end
    cols = (has_default_columns? ? default_event_columns_names : column_names).collect do |name|
      available_columns.find { |col| col.name == name }
    end.compact
    available_columns.select(&:frozen?) | cols
  end
end

class Hash
  def include_hash?(other)
    other.all? do |other_key_value|
      any? { |own_key_value| own_key_value == other_key_value }
    end
  end
end
