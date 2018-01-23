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
  ## get various select elements
  rating = parse_brewery_page.css('div#score_box span[class=ba-ravg]').text.to_f
  types = parse_brewery_page.css('b:contains("Type:")')[0].next.text.strip
  address = parse_brewery_page.css('b:contains("Type:")')[0].next.next_element.text.strip


  {"brewery_name" => brewery_name, \
		"rating" => rating, "types" =>types, \
	  "address" => address}
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
	city_links = get_cities().to_a[0..1].to_h
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
