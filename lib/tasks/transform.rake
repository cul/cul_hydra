# This first line is a temporary fix until we get rid of the dual cul_hydra/cul_scv_hydra nature of this gem.
# Without it, these rake tasks will run twice when invoked.
unless Rake::Task.task_defined?("cul_scv_hydra:transform:marc")

  namespace :cul_scv_hydra do
  
    namespace :transform do
  
      task :marc => :environment do
  
        begin
          src_path = File.join(Rails.root,'fixtures','spec','MARCXML','3867996.xml')
          xsl_path = File.join(Rails.root,'config','xsl','marc_to_mods.xsl')
          doc   = Nokogiri::XML(File.read(src_path))
          xslt  = Nokogiri::XSLT(File.read(xsl_path))
          puts xslt.transform(doc)
        rescue => e
          puts 'Error: ' + e.message
          puts e.backtrace
          next
        end
  
      end
  
    end
  
  end

end