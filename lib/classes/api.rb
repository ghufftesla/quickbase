module Quickbase
  class API
    attr_accessor :connection

    def initialize(connection)
      instance_variable_set "@connection", connection
    end

    # Documentation at http://www.quickbase.com/api-guide/do_query.html
    def do_query(params)
      params[:fmt] = 'structured' if params[:fmt].nil? or params[:fmt].empty?

      clist = params[:clist]
      fidlist = Quickbase::Helper.field_list(clist, @connection)
      params[:clist] = fidlist.join('.')
      friendly = params[:friendly].to_s.split(".")
      keys = friendly.empty? ? ((clist.is_a? String) ? clist.to_s.split('.') : clist) : friendly.map(&:to_sym)

      params[:query] = Quickbase::Helper.query(params[:query], @connection)
      response = connection.http.post("API_DoQuery", Quickbase::Helper.hash_to_xml(params))
      array_of_records = response.xpath("//record[@type='array']/record")
      records = array_of_records.empty? ? response.xpath("//record") : array_of_records
      return [] if records.empty?

      records.map{|record|
        array_of_fields = record.xpath("f[@type='array']/f")
        fields = array_of_fields.empty? ? record.xpath("f") : array_of_fields
        result = Hash[fields.to_enum(:each_with_index).collect{|field,index|
          field_val = ""
          field_val_xpath = field.xpath("__content__").first
          field_val = field_val_xpath.content unless field_val_xpath.nil?
          Hash[keys[index],field_val]
        }.map(&:flatten)]

        # if rid was requested and is present, add it to the results
        rid = Quickbase::Helper.element_content(record, 'rid')
        result['_rid'] = rid if rid
        result
      }
    end

    def do_query_return_nokogiri_obj(params)
      #useful method for debugging
      params[:fmt] = 'structured' if params[:fmt].nil? or params[:fmt].empty?
      clist = params[:clist].to_s.split(".")
      friendly = params[:friendly].to_s.split(".")
      keys = friendly.empty? ? clist : friendly.map(&:to_sym)
      response = connection.http.post("API_DoQuery", Quickbase::Helper.hash_to_xml(params))
      return response
    end

    # Documentation at http://www.quickbase.com/api-guide/add_record.html
    def add_record(fields)
      fields = Quickbase::Helper.generate_fields(fields)
      connection.http.post("API_AddRecord", fields)
    end

    # Documentation at http://www.quickbase.com/api-guide/edit_record.html
    def edit_record(rid, fields)
      tags = Quickbase::Helper.generate_fields(fields)
      tags << Quickbase::Helper.hash_to_xml({:rid => rid.to_s})
      connection.http.post("API_EditRecord", tags)
    end

    # Documentation at http://www.quickbase.com/api-guide/delete_record.html
    def delete_record(rid)
      tags = Quickbase::Helper.hash_to_xml({:rid => rid.to_s})
      connection.http.post("API_DeleteRecord", tags)
    end

    # creates a hash of fields in the connection that map field name to
    # a hash with the numeric field :id and :base_type
    def get_schema()
      response = connection.http.post("API_GetSchema")
      fields = response.xpath("//field[@type='array']/field")
      fields = response.xpath("//field") if fields.empty?
      fields.each do |f|
        id = Quickbase::Helper.element_content(f, 'id')
        label = Quickbase::Helper.element_content(f, 'label')
        type = Quickbase::Helper.element_content(f, 'base-type')
        if id and label and type
          connection.fields[label] = { :id => id, :base_type => type }
        end
      end
    end

  end

  class Api < API
    puts "Class Api will be deprecated. Please use API instead."
  end
end