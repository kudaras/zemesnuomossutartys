#!/usr/bin/ruby

# Skriptas, kuriuo per Google API pagal adresą gaunamos platumos/ilgumos koordinatės

require 'geocoder'
require 'mysql2'

Geocoder.configure(:timeout => 30)

client = Mysql2::Client.new(:host => 'localhost', :username => 'root', :database => 'petras')

sql = client.query("SELECT DISTINCT Sklypo_adresas FROM sklypai WHERE formatted_address IS NULL LIMIT 1000")

sql.each do |row|
	puts sprintf("address: %s",  row["Sklypo_adresas"])
	result = Geocoder.search(row["Sklypo_adresas"])
	components = {}
	if not result.first.nil? and not result.nil?
		lat = result.first.data["geometry"]["location"]["lat"]
		lon = result.first.data["geometry"]["location"]["lng"]
		formatted_address = result.first.data["formatted_address"]
		result.first.data["address_components"].each do |component|
			components[component["types"].first.to_sym] = component["long_name"] if not component["types"].first.nil?
		end

		client.query("UPDATE sklypai SET 
				lat = '#{lat}',
				lon = '#{lon}',
				formatted_address='#{formatted_address}',
				route = '#{components[:route]}',
				country = '#{components[:country]}',
				street_number = '#{components[:street_number]}',
				locality = '#{components[:locality]}',
				street_number = '#{components[:street_number]}',
				postal_code = '#{components[:postal_code]}',
				admin_level_1 = '#{components[:administrative_area_level_1]}',
				admin_level_2 = '#{components[:administrative_area_level_2]}',
				admin_level_3 = '#{components[:administrative_area_level_3]}'
			WHERE Sklypo_adresas='#{row['Sklypo_adresas']}'"
		)
		puts result.first.data["formatted_address"]
	end	
	puts "================="
end

