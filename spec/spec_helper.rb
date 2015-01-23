# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')

require 'bundler/setup'
require 'rspec/rails'
require 'rspec/autorun'
require 'cul_scv_hydra'
require 'equivalent-xml/rspec_matchers'

include EquivalentXml::RSpecMatchers

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end


RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
def absolute_fixture_path(file)
  File.realpath(File.join(File.dirname(__FILE__), '..','fixtures','spec', file))
end
def fixture(file)
  path = absolute_fixture_path(file)
  raise "No fixture file at #{path}" unless File.exists? path
  File.new(path)
end

def attr_name_info(attr_node)
  return {:namespace=>nil, :prefix=>nil, :name=>nil} unless attr_node.type == Nokogiri::XML::Node::ATTRIBUTE_NODE
  parts = attr_node.name().split(':')
  if attr_node.namespace.nil?
    logger.info "no namespace on attribute node"
    if parts.length == 1
      logger.info "no prefix on attribute node"
      return {:namespace=>nil, :prefix=>nil, :name=>parts[0]}
    else
      logger.info parts[0] + " prefix on attribute node"
      _k = 'xmlns:' + parts[0]
      logger.info _k + " maps to namespace " + attr_node.parent.namespaces[_k]
      return {:namespace=>attr_node.parent.namespaces[_k], :prefix=>parts[0], :name=>parts[1]}
    end
  else #has a namespace
    if parts.length == 1 # no prefix
      attr_node.namespaces.each {|k, v|
        if v == attr_node.namespace
          _p = k.split(':')[1]
          return {:namespace=>attr_node.namespace, :prefix=>_p, :name=>attr_node.name}
        end
      }
    else # has prefix
      return {:namespace=>attr_node.namespace, :prefix=>parts[0], :name=>parts[1]}
    end
    return {:namespace=>attr_node.namespace.href, :prefix=>attr_node.namespace.prefix, :name=>parts[-1]}
  end
end

DEFAULT_OPTS = { :element_order => false, :normalize_whitespace => true }

# Determine if two XML documents or nodes are equivalent
#
# @param [Nokogiri::XML::Node] node_1 The first top-level XML node to compare
# @param [Nokogiri::XML::Node] node_2 The secton top-level XML node to compare
# @param [Hash] opts Options that determine how certain comparisons are evaluated
# @option opts [Boolean] :element_order (false) Child elements must occur in the same order to be considered equivalent
# @option opts [Boolean] :normalize_whitespace (true) Collapse whitespace within Text nodes before comparing
# @yield [n1,n2,result] The two nodes currently being evaluated, and whether they are considered equivalent. The block can return true or false to override the default evaluation
# @return [Boolean] true or false
def equivalent?(node_1, node_2, opts = {}, &block)
  opts = DEFAULT_OPTS.merge(opts)
  compare_nodes(as_node(node_1), as_node(node_2), opts, &block)
end

def compare_nodes(node_1, node_2, opts, &block)
  result = nil
  if [node_1, node_2].any? { |node| not node.respond_to?(:node_type) }
    result = node_1.to_s == node_2.to_s
  elsif (node_1.class != node_2.class) or same_namespace?(node_1,node_2) == false
    result = false
  else
    case node_1.node_type
    when Nokogiri::XML::Node::DOCUMENT_NODE
      result = compare_documents(node_1,node_2,opts,&block)
    when Nokogiri::XML::Node::ELEMENT_NODE
      result = compare_elements(node_1,node_2,opts,&block)
    when Nokogiri::XML::Node::ATTRIBUTE_NODE
      result = compare_attributes(node_1,node_2,opts,&block)
    when Nokogiri::XML::Node::CDATA_SECTION_NODE
      result = compare_cdata(node_1,node_2,opts,&block)
    when Nokogiri::XML::Node::TEXT_NODE
      result = compare_text(node_1,node_2,opts,&block)
    else
      result = compare_children(node_1,node_2,opts,&block)
    end
  end
  if block_given?
    block_result = yield(node_1, node_2, result)
    if block_result.is_a?(TrueClass) or block_result.is_a?(FalseClass)
      result = block_result
    end
  end
  return result
end

def compare_documents(node_1, node_2, opts, &block)
  equivalent?(node_1.root,node_2.root,opts,&block)
end

def compare_elements(node_1, node_2, opts, &block)
  (node_1.name == node_2.name) && compare_children(node_1,node_2,opts,&block)
end

def compare_attributes(node_1, node_2, opts, &block)
  (node_1.name == node_2.name) && (node_1.value == node_2.value)
end

def compare_text(node_1, node_2, opts, &block)
  if opts[:normalize_whitespace]
    node_1.text.strip.gsub(/\s+/,' ') == node_2.text.strip.gsub(/\s+/,' ')
  else
    node_1.text == node_2.text
  end
end

def compare_cdata(node_1, node_2, opts, &block)
  node_1.text == node_2.text
end

def compare_children(node_1, node_2, opts, &block)
  ignore_proc = lambda do |child|
    child.node_type == Nokogiri::XML::Node::COMMENT_NODE ||
    child.node_type == Nokogiri::XML::Node::PI_NODE ||
    (opts[:normalize_whitespace] && child.node_type == Nokogiri::XML::Node::TEXT_NODE && child.text.strip.empty?)
  end

  nodeset_1 = node_1.children.reject { |child| ignore_proc.call(child) }
  nodeset_2 = node_2.children.reject { |child| ignore_proc.call(child) }
  result = compare_nodesets(nodeset_1,nodeset_2,opts,&block)

  if node_1.respond_to?(:attribute_nodes)
    attributes_1 = node_1.attribute_nodes
    attributes_2 = node_2.attribute_nodes
    result = result && compare_nodesets(attributes_1,attributes_2,opts,&block)
  end
  result
end

def compare_nodesets(nodeset_1, nodeset_2, opts, &block)
  local_set_1 = nodeset_1.dup
  local_set_2 = nodeset_2.dup

  if local_set_1.length != local_set_2.length
    # return false
  end

  local_set_1.each do |search_node|
    found_node = local_set_2.find { |test_node| equivalent?(search_node,test_node,opts,&block) }
    if found_node.nil?
      logger.error "missing " + search_node.name + " = " + search_node.content
      return false
    else
      if search_node.is_a?(Nokogiri::XML::Element) and opts[:element_order]
        if search_node.parent.elements.index(search_node) != found_node.parent.elements.index(found_node)
          return false
        end
      end
      local_set_2.delete(found_node)
    end
  end
  local_set_2.each {|node| logger.error "extra " + node.name + " = " + node.content}
  return local_set_2.length == 0
end

# Determine if two nodes are in the same effective Namespace
#
# @param [Nokogiri::XML::Node OR String] node_1 The first node to test
# @param [Nokogiri::XML::Node OR String] node_2 The second node to test
def same_namespace?(node_1, node_2)
  args = [node_1,node_2]

  # CharacterData nodes shouldn't have namespaces. But in Nokogiri,
  # they do. And they're invisible. And they get corrupted easily.
  # So let's wilfully ignore them. And while we're at it, let's
  # ignore any class that doesn't know it has a namespace.
  if args.all? { |node| not node.respond_to?(:namespace) } or
     args.any? { |node| node.is_a?(Nokogiri::XML::CharacterData) }
       return true
  end

  href1 = node_1.namespace.nil? ? '' : node_1.namespace.href
  href2 = node_2.namespace.nil? ? '' : node_2.namespace.href
  return href1 == href2
end

def descMetadata(inner_object, file)
  tmpl = Cul::Scv::Hydra::Datastreams::ModsDocument.new(inner_object, 'descMetadata')
  tmpl.ng_xml = Nokogiri::XML::Document.parse(file)
  tmpl.ng_xml_doesnt_change!
  tmpl
end

def structMetadata(inner_object, file)
  tmpl = Cul::Scv::Hydra::Datastreams::StructMetadata.new(inner_object, 'structMetadata')
  tmpl.ng_xml = Nokogiri::XML::Document.parse(file)
  tmpl.ng_xml_doesnt_change!
  tmpl
end

def as_node(data)
  if data.respond_to?(:node_type)
    return data
  else
    result = Nokogiri::XML(data)
    if result.root.nil?
      return data
    else
      return result
    end
  end
end

def fedora_config
  @config ||= begin
    fc = File.exists?('config/fedora.yml') ? 'config/fedora.yml' : 'spec/dummy/config/fedora.yml'
    sc = File.exists?('config/solr.yml') ? 'config/solr.yml' : 'spec/dummy/config/solr.yml'
    {fedora_config_path: fc, solr_config_path: sc}
  end
end
def rubydora_connection
  @configs ||= fedora_config
  @rubydora_conn ||= begin
    ActiveFedora.init(@configs)
    ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)
  end
end
def ingest(pid, foxml, force=false)
  obj = rubydora_connection.connection.find_or_initialize(pid)
  if obj.new?
    rubydora_connection.connection.ingest(:pid=>pid, :file=>foxml)
    return ActiveFedora::Base.find(pid, :cast=>true)
  else
    base = ActiveFedora::Base.find(pid, :cast=>true)
    if force
      base.delete
      rubydora_connection.connection.ingest(:pid=>pid, :file=>foxml)
      return ActiveFedora::Base.find(pid, :cast=>true)
    else
      return base
    end
  end
end
