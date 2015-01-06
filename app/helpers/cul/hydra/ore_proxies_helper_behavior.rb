module Cul::Hydra::OreProxiesHelperBehavior
  def hasModel_name
    @has_model ||= ActiveFedora::SolrService.solr_name('has_model', :symbol)
  end

  def publisher_name
    @has_model ||= ActiveFedora::SolrService.solr_name('publisher', :symbol)
  end

  def facets_for(query, args)
    raw = args.delete(:raw)
    args = args.merge(q:query, qt:'standard',facet:true,rows:0)
    result = ActiveFedora::SolrService.instance.conn.get('select', :params=>args)
    return result if raw
    result['facet_counts']['facet_fields']
  end
  def facet_to_hash(facet_values)
    facet_values ||= []
    hash = {}
    facet_values.each_with_index {|v,ix| hash[v] = facet_values[ix+1] if (ix % 2 == 0)}
    hash
  end
  def proxies(opts=params, &block)
    proxy_in = opts[:id]
    proxy_uri = "info:fedora/#{proxy_in}"
    proxy_id = opts[:proxy_id]
    proxy_in_query = "proxyIn_ssi:#{RSolr.escape(proxy_uri)}"
    f = [proxy_in_query]
    if proxy_id
      f << "belongsToContainer_ssi:#{RSolr.escape(proxy_id)}"
    else
      f << "-belongsToContainer_ssi:*"
    end
    rows = opts[:limit] || '999'
    proxies = ActiveFedora::SolrService.query("*:*",{fq: f,rows:rows})
    if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#FileDataObject'])}
      query = "{!join from=proxyFor_ssi to=identifier_ssim}#{f.join(' ')}"
      files = ActiveFedora::SolrService.query(query,rows:'999')
      proxies.each do |proxy|
        file = files.detect {|f| f['identifier_ssim'].include?(proxy['proxyFor_ssi'])}
        if file
          rels_int = file.fetch('rels_int_profile_tesim',[]).first
          props = rels_int ? JSON.load(rels_int) : {}
          props = props["#{proxy_uri}/content"] || {}
          props['pid'] = file['id']
          props['extent'] ||= file['extent_ssim'] if file['extent_ssim']
          proxy.merge!(props)
        end
      end
    end
    if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#Folder'])}
      query = "{!join from=id  to=belongsToContainer_ssi}#{f.join(' ')}"
      folder_counts = facets_for(query,:"facet.field" => "belongsToContainer_ssi",:"facet.limit" => '999')
      unless ( belongsToContainer = facet_to_hash(folder_counts["belongsToContainer_ssi"])).empty?
        proxies.each do |proxy|
          if proxy["type_ssim"].include?(RDF::NFO[:'#Folder'])
            proxy['extent'] ||= belongsToContainer[proxy['id']]
          end
        end
      end
    end
    if block_given?
      proxies.each &block
    else
      proxies
    end
  end

  def proxies_file_system(opts=params, &block)
    content_tag(:ul, nil, class: 'file-system') do
      proxies(opts, &block)
    end
  end

  def download_permitted?(dl_proxy, args={})
    return permitted_to? :fedora_content, dl_proxy, {:context => :download}
  end

  def proxy_to_download(node, args={})
    dl_proxy = Cul::Scv::DownloadProxy.new(args)
    dl_proxy.content_models = node[hasModel_name()]
    dl_proxy.mime_type = node['format']
    dl_proxy.publisher = node[publisher_name()]
    dl_proxy
  end

  def proxy_extent(node)
    extent = Array(node['extent']).first || '0'
    if node["type_ssim"].include? RDF::NFO[:'#FileDataObject']
      extent = extent.to_i
      if extent > 0
        pow = Math.log(extent,1024).floor
        pow = 3 if pow > 3
        pow = 0 if pow < 0
      else
        pow = 0
      end
      unit = ['B','KiB','MiB','GiB'][pow]
      "#{extent.to_i/(1024**pow)} #{unit}"
    else
      "#{extent.to_i} items"
    end
  end
  def breadcrumbs(opts=params, &block)
    proxy_id = opts[:proxy_id]
    id = opts[:id]
    links = []
    if proxy_id
      parts = proxy_id.split('/')
      id = id.sub('info:fedora/','')
      yield( {id: id, label: 'All Content'})
      # the first three parts are proxied graph prefixes "info:fedora/PID/DSID/..."
      3.upto(parts.size - 2).each do |ix|
        f_id = parts[0..ix].join('/')
        yield( {id: id, proxy_id: URI.escape(f_id), label: parts[ix]})
      end
    end
  end
end