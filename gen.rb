require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'io/console'

$disease_drug_combo = {}
$country_names = CSV.read("countries.csv").flatten!
$and_uri = "+AND+"
$or_uri = "+OR+"
$fields = "[All Fields]"
$mesh = "[MeSH Terms]"
$base_etools = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
$base_pmc = "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/"
$base_oa = "https://www.ncbi.nlm.nih.gov/pmc/oai/oai.cgi"

def to_uri_able (query_term)
    new_terms = (query_term.downcase.split(/[^a-zA-Z0-9]/).map! {|term| URI::encode(term)}.map! {|term|  term + $mesh})*$and_uri
    return  "(" + new_terms + ")"
end

def list_gen(drug_name, disease_name)
    pmc = "pmc"
    pm = "pubmed" 
    ids = get_ids(drug_name, disease_name, pm)
    info = get_info(ids, pm)
    print info[1]
    CSV.open(disease_name+ drug_name+".csv", "wb") do |csv|
      info.each { |art| csv << art }
    end
end

def get_ids (drug_name, disease_name, db)

    ids = []
    terms = ["efficacy", "clincal trial"]
    terms.each do |name|
        query = to_uri_able(drug_name) +  $and_uri  +"\"" + disease_name + "\"" + $mesh + $and_uri  + name + $fields
        doc = Nokogiri::XML(open(URI::encode($base_etools + "esearch.fcgi?db=" + db + "&term=" + query +"&retmax=50")))
       
        ids += doc.xpath("//Id").to_s.split(/<[^>]+>/)
        ids.delete("")
        sleep(0.34)
    end
    ids.uniq!
    return ids
end 
=begin
    pmc_ids.each do |i|
        sleep(0.34)
        url = $base_oa + "?verb=GetRecord&identifier=oai:pubmedcentral.nih.gov:" + i +"&metadataPrefix=" + pmc
        art_doc =  Nokogiri::XML(open(url)).remove_namespaces!
        
        title = art_doc.xpath("//title-group").to_s.split(/<[^>]+>/) * " "
        abstract = art_doc.xpath("//abstract").to_s.split(/<[^>]+>/) * " "
        authors = art_doc.xpath("//contrib", "contrib-type" => "author").to_s.split(/<[^>]+>/) * " "
        articles << [title, authors, abstract] unless (title == "")
    end
=end
def get_info (ids, db)
    id_s = ids * ","
    rv = []
    #https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=protein&id=6678417,9507199,28558982,28558984,28558988,28558990
    #https://www.ncbi.nlm.nih.gov/books/NBK25500/?report=reader#!po=22.0588
    query =  "/efetch.fcgi?db=" + db + "&id=" + id_s + "&rettype=abstract&version=2.0"
    url = $base_etools + query
    art_doc =  Nokogiri::XML(open(url)).remove_namespaces!
    art_doc.xpath("//PubmedArticle").each do |art|
        id = art.xpath("//PMID").to_s.split(/<[^>]+>/) * " "
        title = art.xpath("//ArticleTitle").to_s.split(/<[^>]+>/) * " "
        author = art.xpath("//AuthorList").xpath("//Author").each{ |person| person.to_s.split(/<[^>]+>/) * " " }
        abstract = art.xpath("//AbstractText").to_s.split(/<[^>]+>/) * " "
        rv << [id, title, author, abstract]
    end
    return rv
end




list_gen("Chloroquine+Primaquine", "Plasmodium Vivax")

=begin
references:
https://www.ncbi.nlm.nih.gov/pmc/tools/oai/
https://www.ncbi.nlm.nih.gov/books/NBK25498/
https://www.ncbi.nlm.nih.gov/pmc/tools/id-converter-api/

look in to:
http://eppi.ioe.ac.uk/cms/Default.aspx?tabid=2914
https://www.covidence.org/
=end