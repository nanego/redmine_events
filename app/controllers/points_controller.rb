class PointsController < ApplicationController

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

    scope = @project ? @project.issues.visible : Issue.visible
    @points = scope.includes([:author, :project]).
        joins(:tracker).
        where("trackers.name like 'Point%'").
        order("#{Issue.table_name}.updated_on DESC").
        all
  end

  def create
    @project = Project.find(params[:project_id]) if params[:project_id].present?
    build_new_issue_from_params
    related_evts = Issue.where("id IN (?)", params[:ids])
    @issue.subject = "Point de situation du JJ/MM/YYYY à HH:MM"
    @issue.description ||= ""


    major_events = {}
    related_evts.each do |evt|
      domaine=evt.custom_field_value(CustomField.find_by_name('Domaines')).first
      major_events[domaine] ||= {}
      commune = evt.custom_field_value(CustomField.find_by_name('Commune'))
      major_events[domaine][commune] ||= []
      major_events[domaine][commune] << evt
    end

    @issue.description << "\n# SITUATION GENERALE - FAITS MARQUANTS"
    major_events.each do |domaine, communes|
      # @issue.description << "\n## #{domaine}"
      communes.each do |commune, events|
        events.each do |event|
          resume = event.custom_field_value(CustomField.find_by_name('Résumé'))
          if resume.present?
            @issue.description << "\n\n* #{event.subject} - #{resume}"
          end
        end
      end
    end

    @issue.description << "\n"

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
      @issue.description << "\n# #{domaine}"
      communes.each do |commune, events|
        @issue.description << "\n## #{commune}" if commune.present?
        events.each do |event|
          @issue.description << "\n## #{event.subject}" if event.subject.present?
          @issue.description << "\n#{event.description}" if event.description.present?
        end
      end
    end

    @issue.start_date = DateTime.parse(@issue.start_date.to_s)
    @issue.due_date = DateTime.parse(@issue.start_date.to_s)

    if @issue.save

      related_evts.each do |evt|
        @relation = IssueRelation.new(:relation_type => 'relates')
        @relation.issue_to_id = evt.id
        @relation.issue_from = @issue
        @relation.save
      end

      @issue.journals.destroy_all

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_point_successful_create, :id => view_context.link_to("##{@issue.id}", issue_path(@issue), :title => @issue.subject))
          redirect_to project_point_path(project_id: @issue.project_id, id: @issue.id)
        }
      end
      return
    else
      @point = @issue
      respond_to do |format|
        format.html { render :action => 'index' }
      end
    end
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

    # Force points params
    tracker_point = Tracker.where("name like '%Point%'").first
    @issue.tracker = tracker_point if tracker_point
  end

end

