module Cul
  module Scv
    module Fedora
      module UrlHelperBehavior

        def fedora_url
          @fedora_url ||= ActiveFedora.config.credentials[:url]
        end

        def pid_for_url(pid)
          pid.gsub(/^\//,'').gsub(/info:fedora\//,'')
        end

        def fedora_object_url(pid)
          fedora_url + '/objects/' + pid_for_url(pid)
        end

        def fedora_ds_url(pid, dsid)
          fedora_object_url(pid) + '/datastreams/' + dsid
        end

        def fedora_method_url(pid, method)
          fedora_object_url(pid) + '/methods/' + method
        end

        def fedora_risearch_url
          fedora_url + '/risearch'
        end
      end
    end
  end
end