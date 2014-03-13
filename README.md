# FlattenRecord

An ActiveRecord plugin that denormalizes your existing ActiveRecord models. 

It includes generation of migration, observing the save/destory on target model and changes the records accordingly. It provides an easier way to create denormalized models to be used in reporting.

## Example

### Defining denormalization
    class DenormalizedOrder < ActiveRecord::Base
    	include FlattenRecord::Denormalize

    	denormalize :order do |order|
      		# :belongs_to association
      		order.denormalize :customer
      		
      		# :has_many association, create multiple denormalized records  
      		order.denormalize :line_items do |line_item|
        		line_item.denormalize(:redeem, as: :discount){|d| d.denormalize(:coupon) }
      		end
          order.save :order_sum, :decimal
    	end

    	private
    	def _get_order_sum(order)
      		order.line_items.collect(&:total).inject(:+)
    	end
  	end
  	
### Generating migration file
    $ rails generate flatten_record:migration denormalized_order
	create  db/migrate/20140313034700_create_table_denormalized_orders.rb	
    
### Updating changes and generating migration file
    $ rails generate flatten_record:migration denormalized_order
    Warning. Table already exists: denormalized_orders
	Generating migration based on the difference..
	Add columns: d_line_items_description
      create  db/migrate/20140313034736_add_d_line_items_description_to_denormalized_orders.rb

## Versions

#####v1   
_still in development_  
- denormalize fields and nested fields √  
- denormalize belongs_to, has_many typed associations √    
- generate migration from denormalized model √   
- observe model changes and update denormalized model √  
- ...

## License  
see the MIT-LICENSE.
