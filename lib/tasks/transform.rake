namespace :cul_hydra do

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