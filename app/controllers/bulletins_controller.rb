class BulletinsController < ApplicationController

  before_filter :find_optional_project, :only => [:index]

  def index
    # redirect_to action: 'index', controller: 'issues'
  end

end

