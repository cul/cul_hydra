require 'cul'
require 'json'
module Cul::Scv::Hydra::Controllers
module Terms
  extend ActiveSupport::Concern
  include Blacklight::SolrHelper
  include Stanford::SolrHelper
  include MediaShelf::ActiveFedoraHelper
  included do
    self.before_filter :require_solr, :only=>[:index]
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
    logger.debug solr_params.inspect
    solr_response = Blacklight.solr.get 'terms', {:params => solr_params}
    result = []
    hash = {}
    (1...solr_response['terms'].length).step(2) { |ix|
      _t = solr_response['terms'][ix]
      (0..._t.length).step(2) { |jx|
        result << [_t[jx], _t[jx + 1]]
      }
    }
    logger.debug result.inspect
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

  def field_key_from(field_name, terminology)
    # this is a hack, but necessary until/unless OM generates names differently
   candidates = field_name.split('__')
   field_key = []
   candidates.each_with_index { |candidate, ix|
     if (candidates[ix + 1] and candidates[ix + 1].match(/\d+/))
       field_key << {OM.destringify(candidate) => Integer(candidates.delete_at(ix + 1))}
     else
       field_key << OM.destringify(candidate)
     end
   }
   logger.debug field_key.inspect
   field_key
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