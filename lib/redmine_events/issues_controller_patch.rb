require_dependency 'issues_controller'

class IssuesController

  before_filter :authorize, :except => [:index, :flashs, :create_flash, :description, :show]
  before_filter :find_optional_project, :only => [:index, :flashs]
  before_filter :find_issue, :only => [:show, :edit, :update, :description]

  def description
    respond_to do |format|
      format.html { render :html => "flash", :layout => 'pdf.html' }
      format.pdf { render :pdf => "flash", :layout => 'pdf.html' }
    end
  end

  def flashs

    retrieve_query
    @query.filters = {"tracker_id"=>{:operator=>"=", :values=>["#{Tracker.find_by_name("Flash").id}"]}}
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
        when 'csv', 'pdf'
          @limit = Setting.issues_export_limit.to_i
          if params[:columns] == 'all'
            @query.column_names = @query.available_inline_columns.map(&:name)
          end
        when 'atom'
          @limit = Setting.feeds_limit.to_i
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
          @query.column_names = %w(author)
        else
          @limit = per_page_option
      end

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new @issue_count, @limit, params['page']
      @offset ||= @issue_pages.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group

      respond_to do |format|
        format.html { render :template => 'issues/index', :layout => !request.xhr? }
        format.api  {
          Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
        }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(query_to_csv(@issues, @query, params), :type => 'text/csv; header=present', :filename => 'issues.csv') }
        format.pdf  { send_data(issues_to_pdf(@issues, @project, @query), :type => 'application/pdf', :filename => 'issues.pdf') }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404

  end

  def index
    retrieve_query



        # Custom start
    @query.filters.reverse_merge! "tracker_id"=>{:operator=>"=", :values=>["#{Tracker.find_by_name("Fiche événement").id}"]}
    # Custom end

    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
        when 'csv', 'pdf'
          @limit = Setting.issues_export_limit.to_i
          if params[:columns] == 'all'
            @query.column_names = @query.available_inline_columns.map(&:name)
          end
        when 'atom'
          @limit = Setting.feeds_limit.to_i
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
          @query.column_names = %w(author)
        else
          @limit = per_page_option
      end

      @issue_count = @query.issue_count
      @issue_pages = Paginator.new @issue_count, @limit, params['page']
      @offset ||= @issue_pages.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group

      respond_to do |format|
        format.html { render :template => 'issues/index', :layout => !request.xhr? }
        format.api  {
          Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
        }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(query_to_csv(@issues, @query, params), :type => 'text/csv; header=present', :filename => 'issues.csv') }
        format.pdf  { send_data(issues_to_pdf(@issues, @project, @query), :type => 'application/pdf', :filename => 'issues.pdf') }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create_flash

    @original_issue = Issue.find(params[:issue_id])

    @flash = Issue.new
    @flash.copy_from(@original_issue, :attachments => nil, :subtasks => nil)
    @flash.tracker = Tracker.find_by_name('Flash')

    generate_flash_description

    if @flash.save

      @flash.relations.first.relation_type = 'relates'
      @flash.relations.first.save

      @flash.journals.destroy_all

      redirect_to issue_path(@flash)
    else
      redirect_to issue_path(@original_issue)
    end

  end

  def generate_flash_description
    event_description = @flash.description
    @flash.description = <<HEADER
      <br />
      <div style="text-align: center;margin-top:10px;">
        <table border="2" cellpadding="0" cellspacing="0" id="flash_header" style="border: 2px solid rgb(0, 0, 0); box-shadow: rgb(101, 101, 101) 1px 1px 1px 0px; height: 200px; margin: 10px auto auto; text-align: center; width: 80%;">
          <tbody>
            <tr>
              <td><img alt="" data-rich-file-id="1" src="/system/rich/rich_files/rich_files/000/000/001/original/Logo-Re%CC%81publique-Franc%CC%A7aise.png" style="text-align: center; height: 59px; width: 100px;" /><br style="text-align: center;" />
              <span style="text-align: center; font-family: arial, helvetica, sans-serif;"><strong>Ministère de l'Écologie, du Développement durable et de l'Énergie<br />
              Ministère du Logement, de l'Égalité des territoires et de la Ruralité<br />
              Service de Défense, de Sécurité et d'Intelligence Économique<br />
              <br />
              <span style="font-size: 18px;">FLASH CMVOA N°025</span></strong><br />
              du #{ I18n.l Time.now, format: :complete }</span></td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
HEADER

    @flash.description << <<RESUME
      <div style="text-align: left;"> 
        <table align="center" border="1" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 75%;">
          <tbody>
            <tr>
              <td>
              <div style="text-align: center;">
              <div style="text-align: left;"><em>Sources : DGRS (12:62), SPRM (15:65)</em></div>
              </div>
              <br />
              #{@flash.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['summary_field']))}
              <br /><br />
              <span style="font-size:12px;"><em>Cabinet MEDDE informé.</em></span></td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
RESUME

    @flash.description << <<TITRE
      <table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 80%; background-color: rgb(230, 230, 230);">
        <tbody>
          <tr>
            <td style="text-align: center;"><span style="font-size:18px;">#{@flash.subject}</span></td>
          </tr>
        </tbody>
      </table>
      <br />
TITRE

    @flash.description << <<DOMAINES
      <table align="center" border="1" cellpadding="0" cellspacing="0" style="width: 80%; border: 1px solid rgb(0, 0, 0);">
        <tbody>
          <tr>
            <td style="text-align: center;"><strong><span style="font-size:14px;">
              #{@flash.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['domain_field'])).join('-')}
            </span></strong></td>
          </tr>
        </tbody>
      </table>
      <br />
DOMAINES

    @flash.description << <<DESCRIPTION
      <div style="text-align: left;">
        <table align="center" border="0" cellpadding="0" cellspacing="0" style="width: 75%;">
          <tbody>
            <tr>
              <td>#{event_description}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
DESCRIPTION

  end

end

require_dependency 'issue_query'
class IssueQuery < Query
  class_attribute :context
  def default_columns_names
    @default_columns_names ||= begin
      default_columns = [:id, :priority, :subject, :cf_2, :cf_1, :created_on]
    end
  end
end

module Redmine
  module MenuManager
    module MenuHelper
      def render_single_menu_node(item, caption, url, selected)
        if action_name == "flashs"
          case caption
            when "Evénements"
              selected = false
            when "Flashs"
              selected = true
          end
        end
        link_to(h(caption), url, item.html_options(:selected => selected))
      end
    end
  end
end
