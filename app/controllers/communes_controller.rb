class CommunesController < ApplicationController

  def index
    @communes = Commune.order(:name)
                    .where("lower(name) like lower(?) OR lower(postal_code) like lower(?)", "%#{params[:term]}%", "%#{params[:term]}%")

    result = @communes.map { |c| {id: c.id, name: c.name, department_name: c.department_name, department: c.department} }

    render json: result
  end

  def departments
    @departments = Commune.order(:department, :department_name)
                    .where("lower(department_name) like lower(?) OR lower(department) like lower(?)", "%#{params[:term]}%", "%#{params[:term]}%")
                    .group(:department, :department_name)
                    .pluck(:department_name)
    render json: @departments
  end

end
