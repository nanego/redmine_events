require 'mailer'

class Mailer

  # Builds a mail for send validated Flashes / BS or PS
  def flash(issue, to_users, cc_users)
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id issue
    references issue
    @author = issue.author
    @issue = issue
    @users = to_users + cc_users
    @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
    mail :to => to_users.map(&:mail),
         :cc => cc_users.map(&:mail),
         :subject => "[CMVOA - #{issue.tracker.name} ##{issue.id}] #{issue.subject}"
  end

  # Notifies users about a new issue
  def self.deliver_flash(issue)
    to = issue.notified_users | issue.project.members.map(&:user)  # Ajout de tous les membres du projet, quelque soit leur config
    cc = issue.notified_watchers - to
    issue.each_notification(to + cc) do |users|
      Mailer.flash(issue, to & users, cc & users).deliver
    end
  end

end
