require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'io/console'
require 'sax-machine'

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

def rm_xml_markup (node)
   return node.to_s.split(/<[^>]+>/) * " "
end

def list_gen(drug_name, disease_name)
    pmc = "pmc"
    pm = "pubmed" 
    ids = get_ids(drug_name, disease_name, pm)
    pmc_ids = get_ids(drug_name, disease_name, pmc)
    info = get_info(ids, pm)
    #info_2 = get_info_pmc(pmc_ids)
    #print info[1]
    #CSV.open(disease_name+ drug_name+".csv", "wb") do |csv|
    #  info_2.each { |art| csv << art }
    #end
    CSV.open(disease_name+drug_name+".csv", "wb") do |csv|
       info.each{ |art| csv << art} 
    end
end

def get_ids (drug_name, disease_name, db)

    ids = []
    terms = ["efficacy", "clincal trial"]
    terms.each do |name|
        query = to_uri_able(drug_name) +  $and_uri  +"\"" + disease_name + "\"" + $mesh + $and_uri  + name + $fields
        doc = Nokogiri::XML(open(URI::encode($base_etools + "esearch.fcgi?db=" + db + "&term=" + query +"&retmax=200")))
       
        ids += doc.xpath("//Id").to_s.split(/<[^>]+>/)
        ids.delete("")
        sleep(0.34)
    end
    ids.uniq!
    return ids
end 

def get_info_pmc (pmc_ids)
    articles = []
    pmc_ids.each do |i|
        sleep(0.34)
        url = $base_oa + "?verb=GetRecord&identifier=oai:pubmedcentral.nih.gov:" + i +"&metadataPrefix=" + "pmc"
        art_doc =  Nokogiri::XML(open(url)).remove_namespaces!
        
        title = art_doc.xpath("//title-group").to_s.split(/<[^>]+>/) * " "
        abstract = art_doc.xpath("//abstract").to_s.split(/<[^>]+>/) * " "
        authors = art_doc.xpath("//contrib", "contrib-type" => "author").to_s.split(/<[^>]+>/) * " "
        articles << [title, authors, abstract] unless (title == "")
    end
    return articles
end
def get_info (ids, db)
    p ids.count
    id_s = ids * ","
    rv = []
    #https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=protein&id=6678417,9507199,28558982,28558984,28558988,28558990
    #https://www.ncbi.nlm.nih.gov/books/NBK25500/?report=reader#!po=22.0588
    query =  "/efetch.fcgi?db=" + db + "&id=" + id_s + "&rettype=abstract&version=2.0"
    url = $base_etools + query
    art_doc =  Nokogiri::XML(open(url)).remove_namespaces!
    art_file = File.new("pm_results", "w")
    art_file.write(art_doc)
    art_file.close()
    results = []
    articles = art_doc.xpath("//PubmedArticle").children.each do |art|
        if art.name == "MedlineCitation"
            id = art.xpath(".//PMID").first.inner_text
            author = art.xpath(".//AuthorList").inner_text.gsub(/\s+/, " ")
            title = art.xpath(".//ArticleTitle").inner_text
            abstract = art.xpath(".//AbstractText").inner_text
            year = art.xpath(".//Year").first.inner_text
            link = "https://www.ncbi.nlm.nih.gov/pubmed/" + id
            results << [id, title, author, year, abstract, link] unless author == "" or title == ""
        end
    end

    p results.length
    p results.first.length

    
    return results
end



puts "Enter a disease name: "
disease = gets.chomp
puts "Enter a drug regimine: "
drug = gets.chomp
#list_gen("Chloroquine+Primaquine", "Plasmodium Vivax")
list_gen(disease, drug)
=begin
references:
https://www.ncbi.nlm.nih.gov/pmc/tools/oai/
https://www.ncbi.nlm.nih.gov/books/NBK25498/
https://www.ncbi.nlm.nih.gov/pmc/tools/id-converter-api/

look in to:
http://eppi.ioe.ac.uk/cms/Default.aspx?tabid=2914
https://www.covidence.org/
=end