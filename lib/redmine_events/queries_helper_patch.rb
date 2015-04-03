require_dependency 'queries_helper'

module QueriesHelper
  include IssuesHelper

  unless instance_methods.include?(:column_value_with_limited_visibility)
    def column_value_with_events(column, issue, value)
      case column.name
        when :id
          puts "issue tracker : #{issue.tracker.name}"
          if issue.tracker.name =~ /flash/i
            link_to value, show_flash_path(issue.id)
          else
            link_to value, issue_path(issue)
          end
        when :subject
          if issue.tracker.name =~ /flash/i
            link_to value, show_flash_path(issue.id)
          else
            link_to value, issue_path(issue)
          end
        else
          column_value_without_events(column, issue, value)
      end
    end
    alias_method_chain :column_value, :events
  end
end
