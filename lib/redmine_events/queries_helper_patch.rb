require_dependency 'queries_helper'

module QueriesHelper
  include IssuesHelper

  unless instance_methods.include?(:column_value_with_events)
    def column_value_with_events(column, issue, value)
      case column.name
        when :id
          case issue.tracker.name
            when /flash/i
              link_to value, show_flash_path(issue.id)
            when /bulletin/i
              link_to value, show_bulletin_path(issue.id)
            when /point/i
              link_to value, show_point_path(issue.id)
            else
              link_to value, issue_path(issue)
          end
        when :subject
          case issue.tracker.name
            when /flash/i
              link_to value, show_flash_path(issue.id)
            when /bulletin/i
              link_to value, show_bulletin_path(issue.id)
            when /point/i
              link_to value, show_point_path(issue.id)
            else
              link_to value, issue_path(issue)
          end
        else
          column_value_without_events(column, issue, value)
      end
    end
    alias_method_chain :column_value, :events
  end

  # By default, only display issues which are tagged as "Fiche événement"
  unless instance_methods.include?(:retrieve_query_with_events)
    def retrieve_query_with_events
      retrieve_query_without_events
      if controller_name == 'issues'
        @query.filters.reverse_merge! "tracker_id"=>{:operator=>"=", :values=>["#{Tracker.find_by_name("Fiche événement").id}"]}
      end
    end
    alias_method_chain :retrieve_query, :events
  end

end
