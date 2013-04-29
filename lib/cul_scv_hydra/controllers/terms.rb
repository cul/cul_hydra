require 'cul_scv_hydra'
require 'json'
require 'blacklight'
module Cul::Scv::Hydra::Controllers
module Terms
  extend ActiveSupport::Concern
  included do
    include ::Blacklight::SolrHelper
    #include MediaShelf::ActiveFedoraHelper
  end

  def index
    if params[:layout] == "false"
      layout = false
    end
    if params[:term_id]
      @solr_name = solr_name(params[:term_id])
    else
      @solr_name = params[:solr_name]
    end
    @terms = term_values
    render :action=>params[:action], :layout=>layout
  end

  # this method should be overridden to use the appropriate terminology
  def solr_name(term_id)
    if term_id.nil?
      raise "Cannot provide suggestions without a term name"
    end
    field_key = field_key_from(term_id, Cul::Scv::Hydra::Om::ModsDocument.terminology)
    get_solr_name(field_key, Cul::Scv::Hydra::Om::ModsDocument)
  end
  def term_values
    if @solr_name.nil?
      logger.debug "no solr field name, return nil for term values"
      return nil
    end
    stub = params[:term_value]
    solr_params = {}
    solr_params['wt'] = 'json'
    solr_params['terms'] = 'true'
    solr_params['terms.fl'] = @solr_name
    if stub
      solr_params['terms.lower'] = stub
      solr_params['terms.lower.incl'] = false
      solr_params['terms.prefix'] = stub
      solr_params['terms.sort'] = 'index'
    else
      solr_params['terms.sort'] = params.fetch(:sort,'count')
      solr_params['terms.limit'] = -1
    end
    solr_response = Blacklight.solr.get 'terms', {:params => solr_params}
    result = []
    hash = {}
    (1...solr_response['terms'].length).step(2) { |ix|
      _t = solr_response['terms'][ix]
      (0..._t.length).step(2) { |jx|
        result << [_t[jx], _t[jx + 1]]
      }
    }
    return result
  end

## field_key_from(field_name) to reverse this method from HydraFedoraMetadataHelper
#  def field_name_for(field_key)
#   if field_key.kind_of?(Array)
#     return OM::XML::Terminology.term_hierarchical_name(*field_key)
#   else
#     field_key.to_s
#   end
#  end

  def field_key_from(hier_field_name, t)
   candidates = hier_field_name.split('_')
   field_key = []
   candidates.inject(field_key) { |ptrs, term|
     if term =~ /\d+/
       ptr = {ptrs.pop=>term.to_i}
     else
       ptr = (ptrs.empty? or ptrs.last.is_a? Hash) ? term.to_sym : (ptrs.pop.to_s + "_" + term).to_sym
     end
     ptrs.push ptr   
   }
   return field_key if t.has_term? *field_key
   # pointers are probably from ambiguous underscores
   amb = field_key.dup
   field_key = []
   amb.each do |candidate|
     key = (candidate.is_a? Hash) ? candidate.keys.first : candidate # no indexes should be included
     parts = key.to_s.split('_')
     ptrs = parts_to_terms(parts, t, field_key)
     if ptrs.nil? or !t.has_term? *ptrs
       raise "Couldn't generate pointer from term name going forward for \"" + hier_field_name + "\" (no matched term sequence)"
     else 
       if candidate.is_a? Hash
         ptr_key = ptrs.pop
         ptrs.push({ptr_key => candidate[candidate.keys.first] })
       end
       field_key = ptrs
     end
   end
   return field_key if t.has_term? *field_key
   raise "Couldn't generate pointer from term name going forward for \"" + hier_field_name + "\", tried " + field_key.inspect
  end
  
  def parts_to_terms(parts, t, prefix=[])
    return nil if parts.length == 0 # this should be short-circuited in the loop below rather than recurring
    if parts.length == 1
      new_term_ptr = prefix.dup.push parts[0].to_sym
      if t.has_term? *new_term_ptr
        return new_term_ptr 
      else
        return nil
      end
    end

    results = []
    parts.each_index do |ix|
      term_ptr = prefix.dup.push parts[0...(parts.length - ix)].join('_').to_sym

      if t.has_term? *term_ptr
        case ix
        when 0
          results.push term_ptr
        when 1
          new_term_ptr = term_ptr.concat [parts.last.to_sym]
          results.push new_term_ptr if t.has_term? *new_term_ptr
        else
          new_term_ptr = parts_to_terms(parts[parts.length - ix, ix], t, term_ptr)
          results.push new_term_ptr if !new_term_ptr.nil?
        end
      end
    end

    if results.length == 1
      return results[0]
    else
      return nil
    end
  end

  # ** largely copied from ActiveFedora::NokogiriDatastream.get_values **
  def get_solr_name(term_pointer, dsClass)
    term = dsClass.terminology.retrieve_term(*OM.pointers_to_flat_array(term_pointer, false))
    names = []
    if is_hierarchical_term_pointer?(*term_pointer)
      bases = []
      #add first item in term_pointer as start of bases
      # then iterate through possible nodes that might exist
      term_pointer.first.kind_of?(Hash) ? bases << term_pointer.first.keys.first : bases << term_pointer.first
      for i in 1..(term_pointer.length-1)
        #iterate in reverse so that we can modify the bases array while iterating
        (bases.length-1).downto(0) do |j|
          current_last = (term_pointer[i].kind_of?(Hash) ? term_pointer[i].keys.first : term_pointer[i])
          if (term_pointer[i-1].kind_of?(Hash))
            #just use index supplied instead of trying possibilities
            index = term_pointer[i-1].values.first
            solr_name_base = OM::XML::Terminology.term_hierarchical_name({bases[j]=>index},current_last)
            solr_name = generate_solr_symbol(solr_name_base, term.data_type)
            bases.delete_at(j)
            #insert the new solr name base if found
            bases.insert(j,solr_name_base) if has_solr_name?(solr_name,solr_doc)
          else
            #detect how many nodes exist
            index = 0
            current_base = bases[j]
            bases.delete_at(j)
            solr_name_base = OM::XML::Terminology.term_hierarchical_name({current_base=>index},current_last)
            solr_name = generate_solr_symbol(solr_name_base, term.data_type)
            bases.insert(j,solr_name_base)
          end
        end
      end
      bases.each do |base|
        names << generate_solr_symbol(base.to_sym, term.data_type)
      end
    else
#this is not hierarchical and we can simply look for the solr name created using the terms without any indexes
      generic_field_name_base = OM::XML::Terminology.term_generic_name(*term_pointer)
      names << generate_solr_symbol(generic_field_name_base, term.data_type)
    end
    names
  end

  # ** copied from ActiveFedora::NokogiriDatastream **
  #@return true if the term_pointer contains an index
  # ====Example:
  #     [:image, {:title_set=>1}, :title] return true
  #     [:image, :title_set, :title]      return false
  def is_hierarchical_term_pointer?(*term_pointer)
    if term_pointer.length>1
      term_pointer.each do |pointer|
        if pointer.kind_of?(Hash)
          return true
        end
      end
    end
    return false
  end
  # ** copied from ActiveFedora::NokogiriDatastream **
  def generate_solr_symbol(base, data_type)
    Solrizer::XML::TerminologyBasedSolrizer.default_field_mapper.solr_name(base.to_sym, data_type)
  end
end
end
