module Cul::Hydra::StructMetadataHelperBehavior
  METS_NS = {'mets' => 'http://www.loc.gov/METS/'}
  def mime_for_name(filename)
    ext = File.extname(filename).downcase
    mt = MIME::Types.type_for(ext)
    if mt.is_a? Array
      mt = mt.first
    end
    unless mt.nil?
      return mt.content_type
    else
      return nil
    end
  end

  def html_class_for_filename(filename)
    mime = mime_for_name(filename) || 'application/octet-stream'
    mime.sub(/\//,'_')
  end

  def struct_metadata_ds(doc)
    pid = base_id_for(doc)
    xml = rubydora.datastream_dissemination(:pid=>pid, :dsid=>'structMetadata')
    Cul::Hydra::Datastreams::StructMetadata.from_xml(xml)
  end
  def struct_metadata_file_system_cache_key(doc)
    File.join(doc['id'],'structMetadata','fs-html',doc['system_modified_dtsi'])
  end
  def struct_metadata_file_system(doc)
    ds = struct_metadata_ds(doc)
    doc = Nokogiri::XML(ds.content)
    node = doc.xpath('mets:structMap',METS_NS).first
    content_tag(:ul, nil, class: 'file-system') do
      children_content = node.xpath('mets:div',METS_NS).reduce('') do |content, child|
        content << struct_metadata_node(child)
      end
      children_content.html_safe
    end
  end
  def struct_metadata_node(node)
    children = node.xpath('mets:div',METS_NS)
    if children.length == 0
      # file
      content_tag(:li,nil, class: ['fs-file',html_class_for_filename(node['LABEL'])]) do
        content_tag(:a, node['LABEL'], href: '#', 'data-id'=>node['CONTENTIDS'])
      end
    else
      # folder
      content_tag(:li, nil, class: 'fs-directory') do
        content_tag(:a, node['LABEL'], href: '#') +
        content_tag(:ul, nil, class: 'fs-children') do
          children_content = children.reduce('') do |content, child|
            content << struct_metadata_node(child)
          end
          children_content.html_safe
        end
      end
    end
  end
  def struct_metadata(doc)
    members = get_members(doc)

    node_map = {}
    ds = struct_metadata_ds(doc)
    ds.divs_with_attribute(true,'CONTENTIDS').each do |node|
      node_map[node['CONTENTIDS']] = node
    end
    
    map = {}
    Rails.logger.warn("No members for doc #{doc[:id]}") unless members.size > 0
    members.each do |member|
      ids = ((member[:identifier_ssim] || []) + (member[:dc_identifier_ssim] || []))
      ids.uniq!
      ids.delete(member[:id])
      node_map.each do |cid, node|
        if ids.include? cid
          node['pid'] = member[:id]
          map[member[:id]] = member
          Rails.logger.info("Mapped child node in structMap: '#{member[:id]}'' -> '#{cid}'")
          break
        end
      end
      if map[member[:id]].nil?
        Rails.logger.warn("Unmapped child node in structMap: #{ids.inspect}")
      end
    end
    [ds, map]
  end
end