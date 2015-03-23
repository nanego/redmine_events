namespace :redmine do
  namespace :events do

    require 'csv'

    desc "Import cities from csv file"
    task :import => [:environment] do

      Commune.delete_all

      case ActiveRecord::Base.connection.adapter_name
        when 'SQLite'
          update_seq_sql = "update sqlite_sequence set seq = 0 where name = 'communes';"
          ActiveRecord::Base.connection.execute(update_seq_sql)
        when 'PostgreSQL'
          ActiveRecord::Base.connection.reset_pk_sequence!("communes")
        else
          raise "Task not implemented for this DB adapter"
      end
      puts "Table Communes vide et pk_sequence = 0"

      files = ["plugins/redmine_events/db/seed_data/RE.csv",
               "plugins/redmine_events/db/seed_data/FR.csv"]

      files.each do |file|
        CSV.foreach(file, :headers => false, :col_sep => ";").each_with_index do |row, i|
          puts "Importation : #{i/550.to_i} %" if i % 1000 == 0
          Commune.create!(
            :country => row[0],
            :postal_code => row[1],
            :name => row[2],
            :region => row[3],
            :ref => row[4],
            :department_name => row[5],
            :department => row[6],
            :arrondissement_name => row[7],
            :arrondissement => row[8],
            :latitude => row[9],
            :longtitude => row[10]
          )
        end
      end

    end

  end
end
