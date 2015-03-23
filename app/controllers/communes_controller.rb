class CommunesController < ApplicationController

  def index
    @communes = Commune.order(:name).where("lower(name) like lower(?)", "%#{params[:term]}%").group(:name).pluck(:name)
    render json: @communes
  end

end
