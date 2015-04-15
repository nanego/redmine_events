class BulletinsController < ApplicationController

  before_filter :find_optional_project, :only => [:index]

  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  include Redmine::Export::PDF

  def index
    @project = Project.find(params[:project_id]) if params[:project_id].present?

    @query = IssueQuery.new(:name => "_")
    @query.project = @project
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a
    @query.filters = {"tracker_id"=>{:operator=>"=", :values=>["#{Tracker.where("trackers.name like '%Bulletin%'").first.id}"]}}

    scope = @project ? @project.issues.visible : Issue.visible
    @bulletin = Issue.new # for adding bulletins inline
    @bulletin.start_date = 1.day.ago.strftime("%Y-%m-%d 08:30")
    @bulletin.due_date = Time.now.strftime("%Y-%m-%d 08:30")
    # @bulletin.description = "Bulletin quotidien"
    @bulletins = scope.includes([:author, :project]).
        joins(:tracker).
        where("trackers.name like '%Bulletin%'").
        order("#{Issue.table_name}.updated_on DESC").
        all
  end

  def create
    @project = Project.find(params[:project_id]) if params[:project_id].present?
    build_new_issue_from_params

    @issue.start_date = DateTime.parse(params['issue']['start_date'])
    @issue.due_date = DateTime.parse(params['issue']['due_date'])

    related_evts = Issue.joins(:tracker)
                        .where("trackers.name LIKE '%Fiche %'")
                        .where("updated_on >= ? AND updated_on <= ?", @issue.start_date, @issue.due_date)

    generate_bulletin_description(related_evts)

    @issue.subject = "Bulletin quotidien CMVOA N°#{@issue.id}"

    if @issue.save

      @issue.subject = "Bulletin quotidien CMVOA N°#{@issue.id}"
      @issue.save

      related_evts.each do |evt|
        @relation = IssueRelation.new(:relation_type => 'relates')
        @relation.issue_to_id = evt.id
        @relation.issue_from = @issue
        @relation.save
      end

      @issue.journals.destroy_all

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_bulletin_successful_create, :id => view_context.link_to("##{@issue.id}", issue_path(@issue), :title => @issue.subject))
          redirect_to project_bulletin_path(project_id: @issue.project_id, id: @issue.id)
        }
      end
      return
    else
      @bulletin = @issue
      respond_to do |format|
        format.html { render :action => 'index' }
      end
    end
  end

  def generate_bulletin_description
    event_description = @flash.description
    @flash.description = <<HEADER
      <br />
      <div style="text-align: center;margin-top:10px;">
        <table border="1" cellpadding="0" cellspacing="0" id="flash_header" style="border: 2px solid rgb(0, 0, 0); box-shadow: rgb(101, 101, 101) 1px 1px 1px 0px; height: 200px; margin: 10px auto auto; text-align: center; width: 98%;">
          <tbody>
            <tr>
              <td>
                #{Setting['plugin_redmine_events']['logo_ministere']}<br />
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
              <div style="text-align: left;"><em>Sources : #{@flash.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['source_field'])).join(', ')}</em></div>
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
              #{@flash.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['domain_field'])).join('-')}
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
              <td>#{event_description}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
DESCRIPTION

  end


  def generate_bulletin_description(related_evts)

    @issue.description ||= ""

    major_events = {}
    related_evts.each do |evt|
      domaine=evt.custom_field_value(CustomField.find_by_name('Domaines')).first
      major_events[domaine] ||= {}
      commune = evt.custom_field_value(CustomField.find_by_name('Commune'))
      major_events[domaine][commune] ||= []
      major_events[domaine][commune] << evt
    end

    @issue.description << <<HEADER
      <br />
      <div style="text-align: center;margin-top:10px;">
        <table border="1" cellpadding="0" cellspacing="0" id="flash_header" style="border: 2px solid rgb(0, 0, 0); box-shadow: rgb(101, 101, 101) 1px 1px 1px 0px; height: 200px; margin: 10px auto auto; text-align: center; width: 98%;">
          <tbody>
            <tr>
              <td>#{Setting['plugin_redmine_events']['logo_ministere']}<br/>
              <span style="text-align: center; font-family: arial, helvetica, sans-serif;"><strong>Ministère de l'Écologie, du Développement durable et de l'Énergie<br />
              Ministère du Logement, de l'Égalité des territoires et de la Ruralité<br />
              Service de Défense, de Sécurité et d'Intelligence Économique<br />
              <br />
              <span style="font-size: 18px;">BULLETIN  QUOTIDIEN  CMVOA N° 084</span></strong><br />
              du #{ I18n.l @issue.start_date, format: :complete } au #{ I18n.l @issue.due_date, format: :complete }</span></td>
            </tr>
          </tbody>
        </table>
      </div>
      <br />
HEADER

    @issue.description << <<FAITS_MARQUANTS
      <table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(220, 220, 220);">
        <tbody>
          <tr>
            <td><strong><em><span style="font-size:18px;"> SITUATION GENERALE - PREVISIONS</span></em></strong></td>
          </tr>
        </tbody>
      </table>
FAITS_MARQUANTS






    @issue.description << <<FAITS_MARQUANTS_RESUMES_BEGIN
    <div style="text-align: left;"> 
    <table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
    <tbody>
    <tr>
    <td><strong>Météorologie et crues</strong><br />
      <div style="text-align: center;"><img src="http://www.meteofrance.com/integration/sim-portail/generated/integration/img/vigilance/mn.gif" alt="carte vigilance meteo"/><br />
			<a href="http://france.meteofrance.com/vigilance/Accueil">http://france.meteofrance.com/vigilance/Accueil</a></div>
			<br />
      <strong>Faits marquants</strong>
FAITS_MARQUANTS_RESUMES_BEGIN

    major_events.each do |domaine, communes|
      # @issue.description << "\n## #{domaine}"
      communes.each do |commune, events|
        events.each do |event|
          resume = event.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['summary_field']))
          if resume.present? && event.priority_id >= 3
            @issue.description << <<LIST_FAITS_MARQUANTS
  <ul>
	  <li>#{event.custom_field_value(CustomField.find(11)).present? ? (event.custom_field_value(CustomField.find(11)) + ( Commune.find_by_name(event.custom_field_value(CustomField.find(11))).present? ? ' (' + Commune.find_by_name(event.custom_field_value(CustomField.find(11))).department.to_s.rjust(2, '0') + ')' : '') )  : event.custom_field_value(CustomField.find(9))} : #{resume}</li>
    </ul>
LIST_FAITS_MARQUANTS
          end
        end
      end
    end

    @issue.description << <<FAITS_MARQUANTS_RESUMES_END
			</td>
    </tr>
	</tbody>
    </table>
</div>
FAITS_MARQUANTS_RESUMES_END


    @issue.description << <<INCIDENTS
<table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(220, 220, 220);">
	<tbody>
		<tr>
			<td><strong><em><span style="font-size: 18px;"> PERTURBATIONS, INCIDENTS, ACCIDENTS </span></em></strong></td>
		</tr>
	</tbody>
</table>
<br/>
INCIDENTS

    events = {}
    related_evts.each do |evt|
      evt.custom_field_value(CustomField.find_by_name('Domaines')).each do |domaine|
        events[domaine] ||= {}
        commune = evt.custom_field_value(CustomField.find_by_name('Commune'))
        events[domaine][commune] ||= []
        events[domaine][commune] << evt
      end
    end

    events.each do |domaine, communes|
      @issue.description << <<DOMAINES
<table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(240, 240, 240);">
	<tbody>
		<tr>
			<td><strong><span style="font-size:16px;"> #{domaine}</span></strong></td>
		</tr>
	</tbody>
</table>
<BR/>
DOMAINES

      @issue.description << <<TYPES_START
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
	<tbody>
		<tr>
			<td>
TYPES_START

      communes.each do |commune, events|
        @issue.description << "<strong>#{commune} #{  Commune.find_by_name(commune).present? ? ' (' + Commune.find_by_name(commune).department.to_s.rjust(2, '0') + ')' : ''} :</strong>" if commune.present?
        @issue.description << "<ul>"
        events.each do |event|
          resume = event.custom_field_value(CustomField.find(Setting['plugin_redmine_events']['summary_field']))

          if (event.custom_field_value(CustomField.find(16)).present? || event.custom_field_value(CustomField.find(4)).present?)

            @issue.description << <<TYPES_CONTENT

            <strong><span style="background-color:#FFD700;">Incident #{event.custom_field_value(CustomField.find(2))}</span><br /></strong>

            #{event.custom_field_value(CustomField.find(16)).present? ? event.custom_field_value(CustomField.find(16)) : event.custom_field_value(CustomField.find(4))}<br/>
            #{event.custom_field_value(CustomField.find(7)).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_red.png\' /><span style="padding-left: .6em;">'+event.custom_field_value(CustomField.find(7)).to_s+' morts.</span><br/>').html_safe : ''}
            #{event.custom_field_value(CustomField.find(6)).to_i > 0 ? ('<img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_orange.png\'/><span style="padding-left: .6em;">'+event.custom_field_value(CustomField.find(6)).to_s+' blessés.</span><br/>').html_safe : ''}
            #{event.custom_field_value(CustomField.find(17))}

TYPES_CONTENT

            # #{event.custom_field_value(CustomField.find(17))}

          end

        end
        @issue.description << "</ul>"
      end

      @issue.description << <<TYPES_STOP
			</td>
		</tr>
	</tbody>
</table>
TYPES_STOP

    end

      @issue.description << <<EXERCICES
<table border="1" cellpadding="1" cellspacing="0" id="title" style="border: 1px solid rgb(0, 0, 0); margin: auto; width: 98%; background-color: rgb(220, 220, 220);">
	<tbody>
		<tr>
			<td><strong><em><span style="font-size: 18px;"> EXERCICES (tous domaines) </span></em></strong></td>
		</tr>
	</tbody>
</table>
<br/>
EXERCICES

      @issue.description << <<EXERCICES_CONTENT
<table align="center" border="0" cellpadding="0" cellspacing="0" style="border: 0px solid white; width: 92%;">
	<tbody>
		<tr>
			<td>
        <img style="padding-left: 2.0em;" src=\'/plugin_assets/redmine_events/images/arrow_grey.png\'/> RAS<span style="padding-left: 1.0em;"></span><br/><br/>
			</td>
		</tr>
	</tbody>
</table>
EXERCICES_CONTENT

  end

  def show

    @issue = Issue.find(params[:id])
    @project = @issue.project

    @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    Journal.preload_journals_details_custom_fields(@journals)
    # TODO: use #select! when ruby1.8 support is dropped
    @journals.reject! {|journal| !journal.notes? && journal.visible_details.empty?}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?

    @changesets = @issue.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?

    @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    @relation = IssueRelation.new

    respond_to do |format|
      format.html
      format.api
      format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf  {
        pdf = issue_to_pdf(@issue, :journals => @journals)
        send_data(pdf, :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf")
      }
    end
  end

  private

  def build_new_issue_from_params
    if params[:id].blank?
      @issue = Issue.new
      if params[:copy_from]
        begin
          @copy_from = Issue.visible.find(params[:copy_from])
          @copy_attachments = params[:copy_attachments].present? || request.get?
          @copy_subtasks = params[:copy_subtasks].present? || request.get?
          @issue.copy_from(@copy_from, :attachments => @copy_attachments, :subtasks => @copy_subtasks)
        rescue ActiveRecord::RecordNotFound
          render_404
          return
        end
      end
      @issue.project = @project
    else
      @issue = @project.issues.visible.find(params[:id])
    end

    @issue.project = @project
    @issue.author ||= User.current
    # Tracker must be set before custom field values
    @issue.tracker ||= @project.trackers.find((params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first)
    if @issue.tracker.nil?
      render_error l(:error_no_tracker_in_project)
      return false
    end
    @issue.start_date ||= Date.today if Setting.default_issue_start_date_to_creation_date?
    @issue.safe_attributes = params[:issue]

    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, @issue.new_record?)
    @available_watchers = @issue.watcher_users
    if @issue.project.users.count <= 20
      @available_watchers = (@available_watchers + @issue.project.users.sort).uniq
    end

    # Force bulletins params
    tracker_bulletin = Tracker.where("name like '%Bulletin%'").first
    @issue.tracker = tracker_bulletin if tracker_bulletin
  end

end

