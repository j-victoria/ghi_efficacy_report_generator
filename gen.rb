require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'io/console'

$disease_drug_combo = {}
$country_names = CSV.read("countries.csv").flatten!
$and_uri = "+AND+"
$or_uri = "+OR+"
$efficacy = "efficacy"
$fields = "[All Fields]"
$mesh = "[MeSH Terms]"

def to_uri_able (query_term)
    new_terms = (query_term.downcase.split(/[^a-zA-Z0-9]/).map! {|term| URI::encode(term)}.map! {|term|  term + $fields})*$and_uri
    return  "(" + new_terms + ")"
end

def list_gen (drug_name, disease_name)
    pmc = "pmc"
    base_etools = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
    base_pmc = "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/"
    base_oa = "https://www.ncbi.nlm.nih.gov/pmc/oai/oai.cgi"
    
    query = to_uri_able(drug_name) +  $and_uri  + to_uri_able(disease_name) + $and_uri  + $efficacy + $fields + $and_uri + URI::encode($country_names[1]) + $fields
    doc = Nokogiri::XML(open(base_etools + "esearch.fcgi?db=" + pmc + "&term=" + query +"&retmax=50"))
    #print doc
    ids = doc.xpath("//Id").to_s.split(/<\/?Id>/).uniq
    ids.delete("")
    articles = []
    count = 1
    ids.each do |i|
        sleep(0.5)
        count += 1
        url = base_oa + "?verb=GetRecord&identifier=oai:pubmedcentral.nih.gov:" + i +"&metadataPrefix=" + pmc
        art_doc =  Nokogiri::XML(open(url)).remove_namespaces!
        title = art_doc.xpath("//title-group").to_s
        articles << art_doc.to_s
    end
    fd = IO.sysopen("file.txt", "w")
    a = IO.new(fd, "w")
    a.puts(articles)
end

list_gen("Chloroquine+Primaquine", "Vivax Malaria")

=begin
references:
https://www.ncbi.nlm.nih.gov/pmc/tools/oai/
https://www.ncbi.nlm.nih.gov/books/NBK25498/
https://www.ncbi.nlm.nih.gov/pmc/tools/id-converter-api/
=end