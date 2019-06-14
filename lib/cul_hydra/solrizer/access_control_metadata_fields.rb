module Cul::Hydra::Solrizer
  module AccessControlMetadataFields
    extend ActiveSupport::Concern
    include Cul::Hydra::AccessLevels # useful constants

    XACML_NS = {'xacml'=>'urn:oasis:names:tc:xacml:3.0:core:schema:wd-17'}

    FUNCTION_EMBARGO = "urn:oasis:names:tc:xacml:1.0:function:date-greater-than-or-equal".freeze
    FUNCTION_ONE_STRING_MATCH = "urn:oasis:names:tc:xacml:1.0:function:string-at-least-one-member-of".freeze
    FUNCTION_ONE_URI_MATCH = "urn:oasis:names:tc:xacml:1.0:function:anyURI-at-least-one-member-of".freeze

    TYPE_DATE = "http://www.w3.org/2001/XMLSchema#date".freeze
    TYPE_STRING = "http://www.w3.org/2001/XMLSchema#string".freeze
    TYPE_URI = "http://www.w3.org/2001/XMLSchema#anyURI".freeze

    ATTRIBUTE_AFFILIATION = "http://www.ja-sig.org/products/cas/affiliation".freeze

    def to_solr(solr_doc={})
      solr_doc = (defined? super) ? super : solr_doc

      return solr_doc if policy.nil?  # Return because there is nothing to process
      solr_doc['access_control_levels_ssim'] = access_levels
      solr_doc['access_control_permissions_bsi'] = permissions_indicated?
      solr_doc['access_control_embargo_dtsi'] = permit_after_date
      solr_doc['access_control_affiliations_ssim'] = permit_affiliations
      solr_doc['access_control_locations_ssim'] = permit_locations
      solr_doc
    end

    def policy
      ng_xml.xpath('/xacml:Policy', XACML_NS).first
    end

    def access_levels
      policy&.xpath('./xacml:Rule/xacml:Description', XACML_NS).map(&:text)
    end

    def permissions_indicated?
      permissions&.length > 0
    end

    def permissions
      policy&.xpath('./xacml:Rule[@Effect=\'Permit\']/xacml:Condition', XACML_NS)
    end

    def permit_affiliations
      permissions&.map do |condition|
        if condition.xpath("../xacml:Description", XACML_NS).text.eql?(ACCESS_LEVEL_AFFILIATION)
          if condition['FunctionId'].eql?(FUNCTION_ONE_STRING_MATCH)
            condition.xpath(".//xacml:AttributeValue[@DataType='#{TYPE_STRING}']", XACML_NS).text
          end
        end
      end.compact
    end

    def permit_locations
      permissions&.map do |condition|
        if condition.xpath("../xacml:Description", XACML_NS).text.eql?(ACCESS_LEVEL_ONSITE)
          if condition['FunctionId'].eql?(FUNCTION_ONE_URI_MATCH)
            condition.xpath(".//xacml:AttributeValue[@DataType='#{TYPE_URI}']", XACML_NS).text
          end
        end
      end.compact
    end

    def permit_after_date
      permissions&.map do |condition|
        if condition.xpath("../xacml:Description", XACML_NS).text.eql?(ACCESS_LEVEL_EMBARGO)
          if condition['FunctionId'].eql?(FUNCTION_EMBARGO)
            condition.xpath("./xacml:AttributeValue[@DataType='#{TYPE_DATE}']", XACML_NS).text
          end
        end
      end.compact.first
    end
  end
end