class CommunesController < ApplicationController

  def index
    @communes = Commune.order(:name)
                    .where("lower(name) like lower(?) OR lower(postal_code) like lower(?)", "%#{params[:term]}%", "%#{params[:term]}%")
                    .group(:name)
                    .pluck(:name)
    render json: @communes
  end

end
