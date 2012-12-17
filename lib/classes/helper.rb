module Quickbase
  class Helper
    def self.hash_to_xml(hash)
      hash.map{|key,value|
        "<#{key}>#{value}</#{key}>"
      }
    end

    def self.generate_xml(params)
      Nokogiri::XML("<qdbapi>#{params.join}</qdbapi>")
    end

    def self.generate_fields(fields)
      fields.map{|key,value|
        field = "<field "
        fid = (key =~ /^[-+]?[0-9]+$/) ? field.concat('fid="'+key.to_s+'"') : field.concat('name="'+key.to_s.gsub(/ /, '_') +'"')
        field.concat(">#{value}</field>")
      }
    end

    # returns array of field id strings given an array of field ids or names or
    # a string with dotted field ids or names
    def self.field_list(fields_input, connection)
      fields = (fields_input.is_a? String) ? fields_input.to_s.split(".") : fields_input
      fields.map {|f| self.field_id(f, connection)}.compact
    end

    def self.element_content(xml_node, element_name)
      element = xml_node.xpath(element_name)
      return element.first.content unless element.nil?
      nil
    end

    def self.field_id(field_name, connection)
      (field_name =~ /^[-+]?[0-9]+$/) ? field_name : ((connection.fields[field_name] || {})[:id] || field_name)
    end

    # returns a query string with field ids if field names are used
    def self.query(query, connection)
      if query.is_a? Hash
        # assume exactly equal with AND conditions
        query.map { |k,v|
          "{'#{self.field_id(k, connection)}'.EX.'#{v}'}"
        }.join('AND')
      elsif query.is_a? String
        query.gsub! /\{'([a-zA-Z ]+)'/ do |m|
          fid = self.field_id($1, connection)
          "{'#{fid}'"
        end
        query
      end
    end
  end
end