class CreateCommunes < ActiveRecord::Migration
  def change
    create_table :communes do |t|
      t.string :country
      t.string :postal_code
      t.string :name
      t.string :region
      t.string :ref
      t.string :department_name
      t.string :department
      t.string :arrondissement_name
      t.string :arrondissement
      t.string :latitude
      t.string :longtitude
    end
  end
end
