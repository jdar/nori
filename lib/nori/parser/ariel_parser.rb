dirname = File.dirname(__FILE__)
require_relative dirname+"/nokogiri.rb"
LT_TOKEN = "LeSS_THaN_SYMBaL"
class Nori
  module Parser
    class ArielParser
      def self.parse(xml, options)
        xml = xml.dup
        xml.gsub!("<","#{LT_TOKEN}")

        #switch Ariel tags back
        xml.gsub!("#{LT_TOKEN}l:","<l:")
        xml.gsub!("#{LT_TOKEN}/l:","</l:")

        document = Nori::Parser::Nokogiri::Document.new
        document.options = options
        parser = ::Nokogiri::XML::SAX::Parser.new document
        parser.parse "<root>#{xml}</root>"

        output_hsh = document.stack.length > 0 ? document.stack.pop.to_ariel_hash : {}
        output_hsh = remove_namespace_and_gsub_string_values(output_hsh)
        output_hsh
      end

      def self.remove_namespace_and_gsub_string_values(hsh)
        out = {}
        hsh.each do |k,v|
          if v.is_a?(Hash)
            remove_namespace_and_gsub_string_values(v)
          else #is a string
            #switch Ariel tags back
            v = v.dup
            v.gsub!("#{LT_TOKEN}","<")
            v.gsub!("#{LT_TOKEN}/","</")
            out[k] = v
          end
        end
        out
      end
    end
  end
end

#class Nokogiri::XML::Node
class Nori::XMLUtilityNode
  #TYPENAMES = {1=>'element',2=>'attribute',3=>'text',4=>'cdata',8=>'comment'}
  def to_ariel_hash
    #{kind:TYPENAMES[node_type],name:name}.tap do |h|
    stripped_name = name.gsub(/^l:/,"")
    {name:stripped_name}.tap do |h|
      h.merge! raw: inner_html
      for child in children
        h.merge! child.to_ariel_hash if child.respond_to?(:to_ariel_hash)
      end
    end
  end
end
class Nokogiri::XML::Document
  def to_ariel_hash; root.to_ariel_hash; end
end