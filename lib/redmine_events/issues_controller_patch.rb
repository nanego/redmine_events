# encoding: utf-8

require_dependency 'issues_controller'
include ActionView::Helpers::TextHelper

class IssuesController

  before_filter :find_optional_project_for_events, :only => [:flashs]
  before_filter :find_issue, :only => [:show, :edit, :update, :description, :show_flash]
  before_filter :authorize, :except => [:index, :new, :create, :flashs, :show_flash, :create_flash, :description, :show, :send_flash]
  append_before_filter :update_issue_description, :only => [:description]

  def description
    respond_to do |format|
      format.html { render :pdf => "flash",
                           :layout => 'pdf.html',
                           :background => true,
                           :no_background => false,
                           :show_as_html => true }
      format.pdf { render :pdf => "flash",
                          :layout => 'pdf.html',
                          :show_as_html => params[:debug].present?,
                          :margin => {:bottom => 40},
                          :background => true,
                          :no_background => false,
                          :footer => {:html => {:template => 'layouts/pdf_footer.html.erb'} ,
                                      :margin => {:left => 0, :right => 0, :bottom => 0} } }
    end
  end

  def show_flash
    show
  end

  def flashs

    retrieve_query
    # @query.filters.merge!({"tracker_id"=>{:operator=>"=", :values=>["#{Tracker.find_by_name("Flash").id}"]}})
    @query.filters = {'status_id' => {:operator => 'o', :values => ['']}, "tracker_id"=>{:operator=>"=", :values=>["#{Tracker.find_by_name("Flash").id}"]}}
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

    @original_issue = Issue.find_by_id(params[:issue_id])

    @flash = Issue.new
    @flash.copy_from(@original_issue, :attachments => nil, :subtasks => nil)
    @flash.tracker = Tracker.find_by_name('Flash')

    generate_flash_description(@original_issue)

    @flash.description.gsub! "src='/plugin_assets/", "src='#{request.base_url}/plugin_assets/"
    @flash.description.gsub! 'src="/system/rich/', "src=\"#{request.base_url}/system/rich/"

    @flash.description.gsub! 'src="http:', 'src="https:'
    @flash.description.gsub! "src='http:", "src='https:"

    if @flash.save

      @flash.description.gsub! 'FLASH CMVOA N°025', "FLASH CMVOA N°#{@flash.id}"
      @flash.save

      # Archive old flashes
      @original_issue.relations.each do |relation|
        flash = Issue.find_by_id(relation.issue_to_id)
        if flash.id!=@flash.id && flash.tracker==Tracker.find_by_name('Flash')
          flash.status = IssueStatus.find_by_name('Archivé')
          flash.save
        end
      end

      @flash.reload.relations.first.relation_type = 'relates'
      @flash.relations.first.save

      @flash.journals.destroy_all

      redirect_to show_flash_path(@flash)
    else
      flash[:error] = "Erreur lors de la création du flash. Veuillez signaler ce bug en précisant l'événement concerné. Merci."
      redirect_to issue_path(@original_issue)
    end

  end

  def list_cabinets(issue)
    cabinets_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['cabinets_field'])
    if issue.custom_field_value(cabinets_custom_field).any? { |c| c.present? }
      text = "<br /><span style='font-size:12px;'><em>Cabinets informés :</em></span>"
      issue.custom_field_value(cabinets_custom_field).each do |cab|
        text << "<br /><span style='font-size:12px;'><em>- #{cab}</em></span>" if cab.present?
      end
      text << "<br />"
      text.html_safe
    else
      ""
    end
  end

  def generate_flash_description(original_issue)
    summary_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['summary_field'])
    facts_custom_field = CustomField.find_by_id(16)
    commune_custom_field = CustomField.find_by_id(11)
    departements_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['department_field'])
    domaine_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['domain_field'])
    category_custom_field = CustomField.find_by_id(2)

    dead_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_deads_field'])
    badly_wounded_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_badly_wounded_field'])
    slightly_wounded_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_slightly_wounded_field'])
    wounded_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_wounded_field'])
    lost_number_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['number_of_lost_field'])

    engaged_actions_custom_field = CustomField.find_by_id(17)
    terrorism_custom_field = CustomField.find_by_id(14)
    media_custom_field = CustomField.find_by_id(15)
    start_date_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['start_date_field'])
    end_date_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['end_date_field'])
    event_title_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['event_title_field'])
    infra_map_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['infra_map_field'])
    last_updated_at_custom_field = CustomField.find_by_id(Setting['plugin_redmine_events']['last_updated_at_field'])

    commune = Commune.find_by_name(original_issue.custom_field_value(commune_custom_field))

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
              <div>
                <div style="text-align: left;"><em>#{'Source'.pluralize(original_issue.taggings.size)} : #{original_issue.taggings.map{|source| "#{source.tag.name}#{source.details.present? ? ' ('+source.details.to_s+')' : '' }"}.join(', ')}</em>
                  #{original_issue.custom_field_value(last_updated_at_custom_field).present? ? "<br /><span style='font-size:12px;'><em>Dernière information : #{ I18n.l(DateTime.parse(original_issue.custom_field_value(last_updated_at_custom_field)), format: :complete)}</em></span>".html_safe : ""}
                </div>
              </div>
              <br />
              #{original_issue.custom_field_value(summary_custom_field)}
              <br />
              #{list_cabinets(original_issue)}
              #{original_issue.custom_field_value(media_custom_field).to_i>0 ? "<br /><span style='font-size:12px;'><em>Evénement médiatisé.</em></span>".html_safe : ""}
              #{original_issue.custom_field_value(terrorism_custom_field).to_i>0 ? "<br /><span style='font-size:12px;'><em>Relève du terrorisme.</em></span>".html_safe : ""}
              #{original_issue.custom_field_value(infra_map_custom_field).to_i>0 ? "<br /><span style='font-size:12px;'><em>Carte Infra.</em></span>".html_safe : ""}
              #{original_issue.custom_field_value(start_date_custom_field).present? ? "<br /><span style='font-size:12px;'><em>Début de l'événement : #{ I18n.l(DateTime.parse(original_issue.custom_field_value(start_date_custom_field)), format: :complete)}</em></span>".html_safe : ""}
              #{original_issue.custom_field_value(end_date_custom_field).present? ? "<br /><span style='font-size:12px;'><em>Fin de l'événement : #{ I18n.l(DateTime.parse(original_issue.custom_field_value(end_date_custom_field)), format: :complete)}</em></span>".html_safe : ""}
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
            <td style="text-align: center;"><span style="font-size:18px;">#{original_issue.custom_field_value(event_title_custom_field).present? ? original_issue.custom_field_value(event_title_custom_field) : @flash.subject}</span></td>
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
              #{original_issue.custom_field_value(domaine_custom_field).join('-')}
            </span></strong></td>
          </tr>
        </tbody>
      </table>
      <br />
DOMAINES

    departments = original_issue.custom_field_value(departements_custom_field)
    @flash.description << <<DESCRIPTION
      <div style="text-align: left;">
        <table align="center" border="0" cellpadding="0" cellspacing="0" style="width: 92%;">
          <tbody>
            <tr>
              <td>
                <b>
                  #{if commune.present? || departments.any?{|d|d.present?}
                      txt = commune.present? && departments.size < 2 ? (commune.department_name.to_s + ' (' + commune.department.to_s.rjust(2, '0') + ')' )  : departments.join(', ')
                      txt << ' :'
                      txt
                    end}
                </b>
              </td>
            </tr>
            <tr>
              <td>
                #{original_issue.custom_field_value(facts_custom_field)}<br/>
                #{original_issue.custom_field_value(dead_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_red.png\' /><span style="padding-left: .6em;">'+pluralize(original_issue.custom_field_value(dead_number_custom_field), 'mort')+'</span><br/>').html_safe : ''}
                #{original_issue.custom_field_value(lost_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\'/><span style="padding-left: .6em;">'+pluralize(original_issue.custom_field_value(lost_number_custom_field), 'disparu')+'</span><br/>').html_safe : ''}
                #{original_issue.custom_field_value(badly_wounded_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_red.png\' /><span style="padding-left: .6em;">'+pluralize(original_issue.custom_field_value(badly_wounded_number_custom_field), 'blessé')+' '+'grave'.pluralize(original_issue.custom_field_value(badly_wounded_number_custom_field).to_i)+'</span><br/>').html_safe : ''}
                #{original_issue.custom_field_value(slightly_wounded_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\'/><span style="padding-left: .6em;">'+pluralize(original_issue.custom_field_value(slightly_wounded_number_custom_field), 'blessé')+' '+'léger'.pluralize(original_issue.custom_field_value(slightly_wounded_number_custom_field).to_i)+'</span><br/>').html_safe : ''}
                #{original_issue.custom_field_value(wounded_number_custom_field).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_red.png\' /><span style="padding-left: .6em;">'+pluralize(original_issue.custom_field_value(wounded_number_custom_field), 'blessé')+'</span><br/>').html_safe : ''}
                #{original_issue.custom_field_value(engaged_actions_custom_field)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
DESCRIPTION

    @flash.description << <<SOURCES
     <div style="text-align: right;"><em>#{'Source'.pluralize(original_issue.taggings.size)} : #{original_issue.taggings.map{|source| "#{source.tag.name}#{source.details.present? ? ' ('+source.details.to_s+')' : '' }"}.join(', ')}</em></div>
SOURCES

  end


  def update_issue_description
    @issue.description.gsub! /src=\"\/system.rich/, "src=\"#{WickedPdfHelper.root_path.join('public', 'system', 'rich')}"
    @issue.description.gsub! /http.*cmvoa.*system.rich/, "#{WickedPdfHelper.root_path.join('public', 'system', 'rich')}"
    # @issue.description.gsub! 'https', 'http'
    @issue.description.gsub! /http.*cmvoa.*images/, "#{WickedPdfHelper.root_path.join('public', 'plugin_assets', 'redmine_events', 'images')}"
    @issue.description.gsub! /src='.plugin_assets.*images/, "src='#{WickedPdfHelper.root_path.join('public', 'plugin_assets', 'redmine_events', 'images')}"
  end

  def send_flash
    @original_issue = Issue.find_by_id(params[:issue_id])
    Mailer.deliver_flash(@original_issue)
  end

  private

    def find_optional_project_for_events
      find_optional_project
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
