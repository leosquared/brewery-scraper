## Brewery Scraper

### Summary
This project is aimed to have the most comprehensive user-generated data on carft beers and breweries in the US. It currently consists of a ruby script to scrape data from the [Beer Advocate](https://www.beeradvocate.com) site across major cities in the US. 

### Example URLs
- [City Guide](https://www.beeradvocate.com/place/city/73/)
- [Place](https://www.beeradvocate.com/beer/profile/385/)
- [Beer](https://www.beeradvocate.com/beer/profile/385/18093/)

### Project Plan
- ~~place stats, city stats~~
- ~~scrape all places for cities listed~~
- ~~scrape all metadata for a given *place*~~
- data transformation script
- build linear model to predict place score / beer score
- obtain all individual beers associated wtih the *place*
- obtain all individual reviews associated with a *beer*
- add additional features from individual beers, review text to linear model
- outputs
  - simple REST API, S3 storage
  - map visualization of breweries
  - update schema