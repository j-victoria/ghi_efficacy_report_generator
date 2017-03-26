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
    new_terms = (query_term.downcase.split(/[^a-zA-Z0-9]/).map! {|term| URI::encode(term)}.map! {|term|  term + $mesh})*$and_uri
    return  "(" + new_terms + ")"
end

def list_gen (drug_name, disease_name)
    pmc = "pmc"
    base_etools = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
    base_pmc = "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/"
    base_oa = "https://www.ncbi.nlm.nih.gov/pmc/oai/oai.cgi"
    articles = []
    ids = []
    cited_articles = []
    terms = ["efficacy", "clincal trial"]
    terms.each do |name|
        query = to_uri_able(drug_name) +  $and_uri  +"\"" + disease_name + "\"" + $mesh + $and_uri  + name + $fields + $and_uri #+ URI::encode(name) + $fields
        doc = Nokogiri::XML(open(URI::encode(base_etools + "esearch.fcgi?db=" + pmc + "&term=" + query +"&retmax=50")))
        #print doc
        ids = ids + doc.xpath("//Id").to_s.split(/<\/?Id>/).uniq
        ids.delete("")
        sleep(0.34)
    end
    #print doc
    #print ids.count
    ids.uniq!
    count = 1
    #print name
    #print ids
    ids.each do |i|
        sleep(0.34)
        count += 1
        url = base_oa + "?verb=GetRecord&identifier=oai:pubmedcentral.nih.gov:" + i +"&metadataPrefix=" + pmc
        art_doc =  Nokogiri::XML(open(url)).remove_namespaces!
        title = art_doc.xpath("//article-title").to_s.split(/<[^>]+>/) * " "
        abstract = art_doc.xpath("//abstract").to_s.split(/<[^>]+>/) * " "
        authors = art_doc.xpath("//contrib", "contrib-type" => "author").to_s.split(/<[^>]+>/) * " "
        articles << [title, authors, abstract] unless (title == "")
        cited_articles << art_doc.xpath("//citation//article-title").to_a#.each { |cite| cite.to_s.split(/<[^>]+>/) * " " }
    end
        #fd = IO.sysopen("file.txt", "w")
        #a = IO.new(fd, "w")
        #a.puts(articles)
    
    #articles.uniq!{ |n| n[1] }
    
    print articles.count
    CSV.open(disease_name+ drug_name+".csv", "wb") do |csv|
      articles.each { |art| csv << art }
    end
    cited_articles.uniq!
    print cited_articles[1].class
    CSV.open(disease_name+drug_name+"citations.csv", "wb") do |csv|
      cited_articles.each { |art| csv << art }
    end
end

list_gen("Chloroquine+Primaquine", "Plasmodium Vivax")

=begin
references:
https://www.ncbi.nlm.nih.gov/pmc/tools/oai/
https://www.ncbi.nlm.nih.gov/books/NBK25498/
https://www.ncbi.nlm.nih.gov/pmc/tools/id-converter-api/
=end