require_dependency 'issues_controller'

class IssuesController

  before_filter :find_optional_project, :only => [:index, :flashs]
  before_filter :find_issue, :only => [:show, :edit, :update, :description, :show_flash, :show_point, :show_bulletin]
  before_filter :authorize, :except => [:index, :flashs, :show_flash, :show_point, :show_bulletin, :create_flash, :description, :show, :send_flash]
  append_before_filter :update_issue_description, :only => [:description]

  def description
    respond_to do |format|
      format.html { render :html => "flash",
                           :layout => 'pdf.html' }
      format.pdf { render :pdf => "flash",
                          :layout => 'pdf.html',
                          :show_as_html => params[:debug].present?
      }
    end
  end

  def show_flash
    show
  end
  def show_point
    show
  end
  def show_bulletin
    show
  end

  def flashs

    retrieve_query
    # @query.filters.merge!({"tracker_id"=>{:operator=>"=", :values=>["#{Tracker.find_by_name("Flash").id}"]}})
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
    commune = Commune.find_by_name(@original_issue.custom_field_value(CustomField.find(11)))
    if commune.present?
      @flash.subject = "#{@original_issue.subject}, #{@original_issue.custom_field_value(CustomField.find(11)).present? ? "#{commune.name} ( #{commune.department.to_s.rjust(2, '0')} )" : @original_issue.custom_field_value(CustomField.find(9))}"
    else
      @flash.subject = "#{@original_issue.subject}, #{@original_issue.custom_field_value(CustomField.find(11)).present? ? (@original_issue.custom_field_value(CustomField.find(11)) )  : @original_issue.custom_field_value(CustomField.find(9))}"
    end

    generate_flash_description(@original_issue)

    @flash.description.gsub! "src='/plugin_assets/", "src='#{request.base_url}/plugin_assets/"
    @flash.description.gsub! 'src="/system/rich/', "src=\"#{request.base_url}/system/rich/"

    @flash.description.gsub! 'src="http:', 'src="https:'
    @flash.description.gsub! "src='http:", "src='https:"

    if @flash.save

      @flash.description.gsub! 'FLASH CMVOA N°025', "FLASH CMVOA N°#{@flash.id}"
      @flash.save

      @flash.reload.relations.first.relation_type = 'relates'
      @flash.relations.first.save

      @flash.journals.destroy_all

      redirect_to show_flash_path(@flash)
    else
      redirect_to issue_path(@original_issue)
    end

  end

  def generate_flash_description(original_issue)

    event_description = @flash.description
    commune = Commune.find_by_name(original_issue.custom_field_value(CustomField.find(11)))

    @flash.description = <<HEADER
      <br />
      <div style="text-align: center;margin-top:10px;">
        <table border="1" cellpadding="0" cellspacing="0" id="flash_header" style="border: 2px solid rgb(0, 0, 0); box-shadow: rgb(101, 101, 101) 1px 1px 1px 0px; height: 200px; margin: 10px auto auto; text-align: center; width: 98%;">
          <tbody>
            <tr>
              <td>#{Setting['plugin_redmine_events']['logo_ministere']}<br />
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
        <table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
          <tbody>
            <tr>
              <td>
              <div style="text-align: center;">
              <div style="text-align: left;"><em>Sources : #{original_issue.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['source_field'])).join(', ')}</em></div>
              </div>
              <br />
              #{original_issue.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['summary_field']))}
              <br />
              #{original_issue.custom_field_value(CustomField.find(5)).to_i>0 ? "<br /><span style='font-size:12px;'><em>Cabinet informé.</em></span>".html_safe : ""}
              #{original_issue.custom_field_value(CustomField.find(15)).to_i>0 ? "<br /><span style='font-size:12px;'><em>Evènement médiatisé.</em></span>".html_safe : ""}
              #{original_issue.custom_field_value(CustomField.find(14)).to_i>0 ? "<br /><span style='font-size:12px;'><em>Relève du terrorisme.</em></span>".html_safe : ""}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
RESUME

    @flash.description << <<TITRE
      <table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(230, 230, 230);">
        <tbody>
          <tr>
            <td style="text-align: center;"><span style="font-size:18px;">#{@flash.subject}</span></td>
          </tr>
        </tbody>
      </table>
      <br />
TITRE

    @flash.description << <<DOMAINES
      <table align="center" border="1" cellpadding="0" cellspacing="0" style="width: 98%; border: 1px solid rgb(0, 0, 0);">
        <tbody>
          <tr>
            <td style="text-align: center;"><strong><span style="font-size:14px;">
              #{original_issue.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['domain_field'])).join('-')}
            </span></strong></td>
          </tr>
        </tbody>
      </table>
      <br />
DOMAINES

    @flash.description << <<DESCRIPTION
      <div style="text-align: left;">
        <table align="center" border="0" cellpadding="0" cellspacing="0" style="width: 92%;">
          <tbody>
            <tr>
              <td>
                <b>
                  #{commune.present? ? (commune.department_name.to_s + ' (' + commune.department.to_s.rjust(2, '0') + ')' )  : original_issue.custom_field_value(CustomField.find(9))} :
                </b>
              </td>
            </tr>
            <tr>
              <td>
                #{original_issue.custom_field_value(CustomField.find(16))}<br/>
                #{original_issue.custom_field_value(CustomField.find(7)).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_red.png\' /><span style="padding-left: .6em;">'+original_issue.custom_field_value(CustomField.find(7)).to_s+' morts.</span><br/>').html_safe : ''}
                #{original_issue.custom_field_value(CustomField.find(6)).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\'/><span style="padding-left: .6em;">'+original_issue.custom_field_value(CustomField.find(6)).to_s+' blessés.</span><br/>').html_safe : ''}
                #{original_issue.custom_field_value(CustomField.find(17))}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
DESCRIPTION

  end


  def update_issue_description
    @issue.description.gsub! /src="http.*system\//, "src=\"file:///#{WickedPdfHelper.root_path.join('public', 'system')}"
    # @issue.description.gsub! 'https', 'http'
  end

  def send_flash
    @original_issue = Issue.find(params[:issue_id])
    Mailer.deliver_flash(@original_issue)
  end

end

module Redmine
  module MenuManager
    module MenuHelper
      def render_single_menu_node(item, caption, url, selected)
        if action_name == "flashs" || action_name == 'show_flash'
          case caption
            when "Evénements"
              selected = false
            when "Flashs"
              selected = true
          end
        end
        if action_name =~ /bulletin/i
          case caption
            when "Evénements"
              selected = false
            when /bulletin/i
              selected = true
          end
        end
        if action_name =~ /point/i
          case caption
            when "Evénements"
              selected = false
            when "Points de situation"
              selected = true
          end
        end
        link_to(h(caption), url, item.html_options(:selected => selected))
      end
    end
  end
end
