# config/initializers/zeitwerk.rb
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "dc_metadata" => "DCMetadata",
    "fcrepo3" => "FCREPO3",
    "nie" => "NIE",
    "nfo" => "NFO",
    "olo"   => "OLO",
    "ore"   => "ORE",
    "pimo" => "PIMO",
    "rdf" => "RDF",
    "sc" => "SC"
  )
end