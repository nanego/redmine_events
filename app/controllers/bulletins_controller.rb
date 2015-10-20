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
  include EventsHelper
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
    @issue.subject = "Bulletin quotidien CMVOA"

    if @issue.save

      related_evts = Issue.joins(:tracker)
                         .where("trackers.name LIKE '%Fiche %'")
                         .where("updated_on >= ? AND updated_on <= ?", @issue.start_date, @issue.due_date)

      generate_bulletin_description(related_evts)

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

  def generate_bulletin_description(related_evts)
    @issue.description ||= ""
    @issue.description << bulletin_header(@issue)
    @issue.description << bulletin_main_facts(@issue, related_evts)
    @issue.description << bulletin_incidents(@issue, related_evts)
    @issue.description << bulletin_exercices
  end

  def show
    @issue = Issue.find(params[:id])
    @project = @issue.project

    @journals = @issue.journals.includes(:user, :details)
                    .references(:users, :details)
                    .reorder(:created_on, :id).to_a
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    Journal.preload_journals_details_custom_fields(@journals)
    @journals.select! {|journal| journal.notes? || journal.visible_details.any?}
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

    @issue = Issue.new
    if params[:copy_from]
      begin
        @issue.init_journal(User.current)
        @copy_from = Issue.visible.find(params[:copy_from])
        unless User.current.allowed_to?(:copy_issues, @copy_from.project)
          raise ::Unauthorized
        end
        @link_copy = link_copy?(params[:link_copy]) || request.get?
        @copy_attachments = params[:copy_attachments].present? || request.get?
        @copy_subtasks = params[:copy_subtasks].present? || request.get?
        @issue.copy_from(@copy_from, :attachments => @copy_attachments, :subtasks => @copy_subtasks, :link => @link_copy)
      rescue ActiveRecord::RecordNotFound
        render_404
        return
      end
    end
    @issue.project = @project
    if request.get?
      @issue.project ||= @issue.allowed_target_projects.first
    end
    @issue.author ||= User.current
    @issue.start_date ||= Date.today if Setting.default_issue_start_date_to_creation_date?

    if attrs = params[:issue].deep_dup
      if action_name == 'new' && params[:was_default_status] == attrs[:status_id]
        attrs.delete(:status_id)
      end
      @issue.safe_attributes = attrs
    end
    if @issue.project
      @issue.tracker ||= @issue.project.trackers.first
      if @issue.tracker.nil?
        render_error l(:error_no_tracker_in_project)
        return false
      end
      if @issue.status.nil?
        render_error l(:error_no_default_issue_status)
        return false
      end
    end

    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, @issue.new_record?)

    # Force bulletins params
    tracker_bulletin = Tracker.where("name like '%Bulletin%'").first
    @issue.tracker = tracker_bulletin if tracker_bulletin
  end

end

