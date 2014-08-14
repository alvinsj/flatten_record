module FlattenRecord
  class DenormalizedSet < ::Array
    def self.init(items=nil)
      arr = self.new 
      if items.respond_to?(:each)
        items.each{|a| arr.push(a) unless a.nil?}
      else
        arr.push(items)
      end
      arr
    end

    def merge(items)
      items = [items] unless items.respond_to?(:each)
      items.select do |item|
        include?(item)
      end 
      concat(items)
    end

    def find_match(normal, normalized_attr)
      select do |denormalized|
        id_name = normalized_attr.id_column.name
        normal_id_name = normalized_attr.id_column.column.name
        id_val = denormalized.send(id_name)
        normal_id_val = normal.send(normal_id_name)
        
        id_val == normal_id_val
      end
    end

    private
    def make_enum(items)
      [items].flatten
    end
  end
end
