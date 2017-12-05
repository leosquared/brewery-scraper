require 'HTTParty'
require 'Nokogiri'
require 'json'
require 'csv'

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

def run_city(city, link)
	## get links by section
	city_page = HTTParty.get(link)
	parse_city_page = Nokogiri::HTML(city_page)
	breweries = {}

	parse_city_page.css('h6+ul')[0].css('li').each_with_index do |element, i|
		brewery_link = @domain_url + element.css('a')[0]['href']
		brewery_page = HTTParty.get(brewery_link)
		parse_brewery_page = Nokogiri::HTML(brewery_page)
		rating = parse_brewery_page.css('div#score-box span[class=ba-ravg]').text.to_i
		breweries[element.css('b').text] = {'brewery_link'=>brewery_link, 'address'=>element.css('span').text, 'rating'=>rating}
		$count = i

	end
	
	open("outputs/#{city}.json" % city, "w").write(JSON.pretty_generate(breweries))
	puts "#{city} file generated with #{$count} breweries found"

end

if __FILE__ == $0
	@domain_url = 'https://www.beeradvocate.com'
	city_links = get_cities()
	city_links.each do |city, link|
		retries = 3
		begin
			run_city(city, link)
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
end
