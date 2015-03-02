module Cul
  module Hydra
    module Fedora
      autoload :DummyObject, 'cul_hydra/fedora/dummy_object'
      autoload :RubydoraPatch, 'cul_hydra/fedora/rubydora_patch'
      autoload :UrlHelperBehavior, 'cul_hydra/fedora/url_helper_behavior'
      def self.config_path
        File.join(Rails.root.to_s, 'config', 'fedora.yml')
      end
      def self.config
        ActiveFedora.fedora_config.credentials
      end
      def self.connection
        @connection ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.fedora_config.credentials)
      end

      def self.repository
        @repository ||= begin
          repo = connection.connection
          repo.extend(RubydoraPatch)
          repo
        end
      end

      def self.ds_for_uri(fedora_uri, fake_obj=nil)
        return nil unless fedora_uri =~ /info\:fedora\/.*/
        p = fedora_uri.split('/')
        return ds_for_opts({pid: p[1], dsid: p[2]})
      end

      def self.ds_for_opts(opts={}, fake_obj=nil)
        return nil unless opts[:pid] and opts[:dsid]
        fake_obj = fake_obj.nil? ? DummyObject.new(opts[:pid]) : fake_obj.spawn(opts[:pid])
        return (opts[:class] || ::Rubydora::Datastream).new(fake_obj, opts[:dsid])
      end
    end
  end
end