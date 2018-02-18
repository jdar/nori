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

        output_hsh = document.stack.length > 0 ? document.stack[1].to_ariel_hash : {}
        output_hsh = remove_namespace_and_gsub_string_values(output_hsh)
        output_hsh
      end

      def self.remove_namespace_and_gsub_string_values(hsh)
        out = {}
        if hsh[:children]
          out[:children] = hsh[:children].map {|name,child_hsh| remove_namespace_and_gsub_string_values child_hsh }
        end
        #switch Ariel tags back
        out[:name] = hsh[:name]
        for k,v in {raw: hsh[:raw]}

          #eliminate the \l: tags
          v.gsub!(/<[\/\w-:]+>/,"")

          v.gsub!("#{LT_TOKEN}","<")
          v.gsub!("#{LT_TOKEN}/","</")
          out[k] = v
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
    stripped_name = name.to_s.gsub(/^l:/,"")
    {name:stripped_name}.tap do |h|
      h.merge! raw: inner_html.strip
      kids = {}
      for child in children
        next unless child.respond_to?(:name)
        kids[child.name] = child.to_ariel_hash if child.respond_to?(:to_ariel_hash)
      end
      h.merge! :children => kids unless kids.empty?
    end
  end
end
class Nokogiri::XML::Document
  def to_ariel_hash; root.to_ariel_hash; end
end