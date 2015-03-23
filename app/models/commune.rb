class Commune < ActiveRecord::Base
  attr_accessible :arrondissement, :arrondissement_name, :country, :department, :department_name, :latitude, :longtitude, :name, :postal_code, :ref, :region
end
