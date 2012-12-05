APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../")

def filename_for_pid(pid)
  pid.gsub(/\:/,'_') + '.xml'
end

def pid_for_filename(fname)
  fname.sub(/\.xml$/,'').sub(/_/,':')
end

def cmodel_fixture(name)
  path = File.join(APP_ROOT, 'fixtures','cmodels',name)
  File.open(path, 'rb')
end

def each_cmodel
  path = File.join(APP_ROOT, 'fixtures','cmodels')
  Dir.new(path).each do |fname|
    if fname =~ /\.xml$/
      yield pid_for_filename(fname)
    end
  end
end

def config_subs
  cfile = File.open(File.join(APP_ROOT,'config','subs.yml'))
  YAML::load(cfile)[Rails.env]
end

def do_subs(orig)
  content = orig.clone
  config_subs.each do |key, val|
    content.gsub!(/\$#{key.to_s}\$/, val)
  end
  content
end

def connection
  @connection ||= (ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)).connection
end

def content_for(pid)
  fname = filename_for_pid(pid)
  fcontent = cmodel_fixture(fname).read
  fcontent = do_subs(fcontent)
end

def load(content, pid)
  connection.ingest(:file=>StringIO.new(content), :pid=>pid)
end

def purge(pid)
  connection.purge_object :pid=>pid
end

def reload(pid)
  fcontent = content_for(pid)
  purge(pid)
  load(fcontent, pid)
end
  

namespace :cul_scv_hydra do
  namespace :cmodel do
    task :test => :environment do
      pid = ENV["PID"]
      puts content_for(pid)
    end

    task :load => :environment do
      pid = ENV["PID"]
      load(content_for(pid),pid)
    end

    task :purge => :environment do
      pid = ENV["PID"]
      purge(pid)
    end

    task :reload => :environment do
      pid = ENV["PID"]
      reload(pid)
    end

    task :reload_all => :environment do
      pattern = ENV["PATTERN"]
      pattern = Regexp.compile(pattern) if pattern
      each_cmodel do |pid|
        unless (pattern and not pid =~ pattern)
          puts "reloading #{pid}"
          reload(pid)
        end
      end
    end
  end
end
