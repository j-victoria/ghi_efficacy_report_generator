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
    pm = "pubmed"
    base_etools = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
    base_pmc = "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/"
    base_oa = "https://www.ncbi.nlm.nih.gov/pmc/oai/oai.cgi"
    articles = []
    pmc_ids = []
    pm_ids = []
    cited_articles = []
    terms = ["efficacy", "clincal trial"]
    terms.each do |name|
        query = to_uri_able(drug_name) +  $and_uri  +"\"" + disease_name + "\"" + $mesh + $and_uri  + name + $fields + $and_uri #+ URI::encode(name) + $fields
        pmc_doc = Nokogiri::XML(open(URI::encode(base_etools + "esearch.fcgi?db=" + pmc + "&term=" + query +"&retmax=50")))
        sleep(0.34)
        pm_doc = Nokogiri::XML(open(URI::encode(base_etools + "esearch.fcgi?db=" + pm + "&term=" + query +"&retmax=50")))
        #print doc
        pmc_ids = pmc_ids + pmc_doc.xpath("//Id").to_s.split(/<\/?Id>/).uniq
        pmc_ids.delete("")
        pm_ids += pm_doc.xpath("//Id").to_s.split(/<[^>]+>/).uniq
        
        sleep(0.34)
    end
    #print doc
    #print pmc_ids.count
    pmc_ids.uniq!
    count = 1
    #print name
    #print pmc_ids
    pmc_ids.each do |i|
        sleep(0.34)
        count += 1
        url = base_oa + "?verb=GetRecord&identifier=oai:pubmedcentral.nih.gov:" + i +"&metadataPrefix=" + pmc
        art_doc =  Nokogiri::XML(open(url)).remove_namespaces!
        title = art_doc.xpath("//article-title").to_s.split(/<[^>]+>/) * " "
        abstract = art_doc.xpath("//abstract").to_s.split(/<[^>]+>/) * " "
        authors = art_doc.xpath("//contrib", "contrib-type" => "author").to_s.split(/<[^>]+>/) * " "
        articles << [title, authors, abstract] unless (title == "")
        citations = art_doc.xpath("//ref-list").xpath("//ref").xpath("//article-title").to_a
        citations.each{ |citation| citation =
        [citation.xpath("//article-title").to_s.split(/<[^>]+>/) * " ", 
        citation.xpath("//source").to_s.split(/<[^>]+>/) * " ", 
        ]}#citation.xpath("//pub-id").to_a.each{ |id| id.to_s.split(/<[^>]+>/) * " "}] }
        #print citations
        cited_articles += citations
    end
    
    pm_ids.uniq!
    id_s = pm_ids * ","
    #https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=protein&id=6678417,9507199,28558982,28558984,28558988,28558990
    #https://www.ncbi.nlm.nih.gov/books/NBK25500/?report=reader#!po=22.0588
    query =  "/efetch.fcgi?db=" + pm + "&id=" + id_s + "&rettype=abstract&version=2.0"
    url = base_etools + query
    art_doc =  Nokogiri::XML(open(url)).remove_namespaces!
    
    #print art_doc
    CSV.open(disease_name+ drug_name+".csv", "wb") do |csv|
      articles.each { |art| csv << art }
    end
    cited_articles.uniq!
    c_a_s = []
    cited_articles.each{ |cite| c_a_s << [cite.to_s.split(/<[^>]+>/) * " "] }
    #cited_articles.each{ |art| art.to_a.each{|title| title.to_s} }
    #print cited_articles[1]
    #print cited_articles.count
    #print c_a_s[1]
    CSV.open(disease_name+drug_name+"_citations.csv", "wb") do |csv|
      c_a_s.each {|art| csv << art }
    end
end

list_gen("Chloroquine+Primaquine", "Plasmodium Vivax")

=begin
references:
https://www.ncbi.nlm.nih.gov/pmc/tools/oai/
https://www.ncbi.nlm.nih.gov/books/NBK25498/
https://www.ncbi.nlm.nih.gov/pmc/tools/id-converter-api/
=end