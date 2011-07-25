$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
#require 'om'
require 'cul_om_scv'
require 'spec'
require 'spec/autorun'
require 'equivalent-xml/rspec_matchers'
require 'ruby-debug'

ActiveFedora.init(File.join(File.dirname(__FILE__), "..", "config", "fedora.yml"))

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

def fixture(file)
  File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
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
