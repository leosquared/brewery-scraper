require 'HTTParty'
require 'Nokogiri'
require 'json'
require 'csv'
require 'date'

def get_cities
	page = HTTParty.get('https://www.beeradvocate.com/place/directory/9/US/')
	parse_page = Nokogiri::HTML(page)

	## grab links to each American City Guide
	city_links = {}
	parse_page.css('a[href*="city"]').each do |element|
		city_links[element.text] = @domain_url + element['href']
	end
	city_links
end


def run_brewery(brewery_link, brewery_name)
  
  brewery_page = HTTParty.get(brewery_link)
  parse_brewery_page = Nokogiri::HTML(brewery_page)
  brewery_meta = {}
  
  ## get various select elements
  brewery_meta["brewery_name"] = brewery_name
  brewery_meta["rating"] = parse_brewery_page.css('div#score_box span[class=ba-ravg]').text.to_f
  info_box_text = []
	
	parse_brewery_page.css('div#info_box').children.each_with_index do |child, i|
		if child.text.strip != ""
			info_box_text << child.text.strip
		end
	end
	
	beer_stats, place_stats = parse_brewery_page.css('div[id="item_stats"]')[0..1]

	## Beer Stats
	unless beer_stats.nil?
		beer_stats_hash = {}
		beer_stats_arr = beer_stats.text.strip().split("\n").map(&:strip)
		beer_stats_arr.delete("")
		beer_stats_arr.each_with_index do |element, i|
			data_field = /(.*):/.match(element.strip)
			unless data_field.nil?
				data_value = beer_stats_arr[i+1].delete(",")
				data_value_i ||= data_value.to_i if /^\d+$/.match?(data_value)
				beer_stats_hash[data_field[0]] = data_value_i || data_value
			end
			brewery_meta["beer_stats"] = beer_stats_hash
		end
	end

	## Place Stats
	unless place_stats.nil?
		place_stats_hash = {}
		place_stats_arr = place_stats.text.strip().split("\n").map(&:strip)
		place_stats_arr.delete("")
		place_stats_arr.each_with_index do |element, i|
			data_field = /(.*):/.match(element.strip)
			unless data_field.nil?
				data_value = place_stats_arr[i+1].delete(",")
				data_value_i ||= data_value.to_i if /^\d+$/.match?(data_value)
				place_stats_hash[data_field[0]] = data_value_i || data_value
			end
			brewery_meta["place_stats"] = place_stats_hash
		end
	end

	## Place Info
	addr_elements = []
	info_box_text.each_with_index do |tag, i|
		if ["PLACE INFO", "map"].include?(tag)
		elsif /\([0-9]+\)/.match?(tag)
			brewery_meta["phone"] = tag.scan(/[0-9]/).to_a.join()
		elsif /Added by.*/.match?(tag)
			brewery_meta["author"] = /Added by *(?<name>[a-zA-Z]*) ?\w* ?(?<date>[0-9\-]+$)?/.match(tag).named_captures
		elsif /.+(\.com|\.org|\.net)$/.match?(tag)
			brewery_meta["website"] = tag
		elsif tag == "Type:"
			brewery_meta["types"] = info_box_text[i+1].split(", ")
			info_box_text.delete_at(i+1)
		elsif tag == "Notes:"
			brewery_meta["notes"] = info_box_text[i+1]
			info_box_text.delete_at(i+1)
		else
			addr_elements << tag
		end
	end
	brewery_meta["address"] = addr_elements.join(" ")

  brewery_meta
end


def run_city(city, link)
	## get links by section
	city_page = HTTParty.get(link)
	parse_city_page = Nokogiri::HTML(city_page)
	breweries = {}

	## given a city page, run through list of breweries and get metadata
	parse_city_page.css('h6+ul')[0].css('li').each_with_index do |element, i|
		brewery_link = @domain_url + element.css('a')[0]['href']
		brewery_name = element.css('b').text
		brewery_page = HTTParty.get(brewery_link)
		parse_brewery_page = Nokogiri::HTML(brewery_page)
		breweries[brewery_name] = run_brewery(brewery_link, brewery_name)

		$count = i

	end
	
	# open("outputs/#{city}.json" % city, "w").write(JSON.pretty_generate(breweries))
	puts "#{city} ran with #{$count} breweries found"
	breweries
end

if __FILE__ == $0
	@domain_url = 'https://www.beeradvocate.com'
	write_data = {}
	city_links = get_cities().to_a[0..5].to_h ####### change this to run the whole dataset
	city_links.each do |city, link|
		## retry counts for each city
		retries = 3
		begin
			write_data[city] = run_city(city, link)
		rescue Exception=>e
			puts "#{e}"
			if retries > 0
				retries -= 1
				puts "Retrying..."
				sleep 2
				retry
			end
		end
	end
	open("outputs/job_%s.json" % DateTime.now.strftime("%Y%m%d_%H%M"), "a").write(JSON.pretty_generate(write_data))
end
