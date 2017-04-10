Goal: To generate a csv of info used for systematic reviews.

Technical Details:
Ruby 2.3.0
Nokogiri 1.7.0.1
run on Ubuntu 14.04.5 LTS

Using NIH E-Utilities
Guides can be found here: https://www.ncbi.nlm.nih.gov/books/NBK25501

functions:

list_gen: calls the other functions. creates a CSV

get_ids: queries E-Utilities with the given parameters, where drug name is separated, as mesh terms + 'efficacy' or 'clinical trial.' Processes the returned XML file. Returns an array of IDs.

get_info: Does an E-fetch on the suplimented ids. Processes the XML file for information such as title, authors and abstract. Returns an array of the information.
