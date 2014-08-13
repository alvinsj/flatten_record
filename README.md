# FlattenRecord [![Code Climate](https://codeclimate.com/github/alvinsj/flatten_record.png)](https://codeclimate.com/github/alvinsj/flatten_record)  [![Build Status](https://travis-ci.org/alvinsj/flatten_record.png?branch=master)](https://travis-ci.org/alvinsj/flatten_record)

An ActiveRecord plugin that denormalizes your existing ActiveRecord models. 

It includes generation of migration, observing the save/destory on target model and changes the records accordingly. It provides an easier way to create denormalized models to be used in reporting.

## Usage

### Add gem dependency
    gem 'flatten_record'

### Include module
	include FlattenRecord::Flattener
	
### Define denormalization
	class Order < ActiveRecord::Base
		def total_in_usd
			# calculation
		end
	end
	
    class DenormalizedOrder < ActiveRecord::Base
    	include FlattenRecord::Flattener

    	denormalize :order, {
      		include: { 
      		    # :belongs_to association
      			customer: {}
      		
      			# :has_many association, create multiple denormalized records  
      			line_items: {}
  			},
  			method: [
          		# save methods defined in Normalized model
          		:total_in_usd
          	],
          	compute: [
          		# new integer column with method defined below
          		:line_items_sum,
          		
          		# new column with different type
          		{ details: { sql_type: :string} }
          	]
    	}

    	private
    	def line_item_sum(order)
      		order.line_items.collect(&:total).inject(:+)
    	end
  	end
  	
### Generate migration file
    $ rails generate flatten_record:migration denormalized_order
	  create  db/migrate/20140313034700_create_table_denormalized_orders.rb	
    
### Update changes and generate new migration file
    $ rails generate flatten_record:migration denormalized_order
    Warning. Table already exists: denormalized_orders
	Generating migration based on the difference..
	Add columns: d_line_items_description
      create  db/migrate/20140313034736_add_d_line_items_description_to_denormalized_orders.rb
      

### Denormalization methods
#### Create record(s)
	irb(main)> DenormalizedOrder.create_with(order)

#### Deleting record(s)
	irb(main)> DenormalizedOrder.destroy_with(order)

#### Update record(s)
	irb(main)> DenormalizedOrder.update_with(order)

## Other Modules

### Model Observer
Observe changes in the normalized model and create denormalized records. 

The implementaion uses `after_commit` method in `ActiveRecord::Observer`.  
(_Note: normalized model and all its children will be observed._)

Add gem dependency
 
	gem 'rails-observers'
	
Include module in denormalized model, then observers will be included.
	
	include FlattenRecord::Observer
	
Eager loading is required to load _ActiveRecord::Observer_ on app initialization.  
	
	# under initializers/<denormalize>.rb or lib/<engine>/engine.rb 
	config.after_initialize do
      require_dependency root.join('app/models/denormalized_order').to_s
    end
    
## Versions

#####v1  
- tree-based denormalization: nicer code & structure √ 
- new DSL + syntax √ 
- custom column prefix in denormalized table √  
- introduce :methods & :compute √ 
- update denormalized records 
- remove rails gem dependency

#####v0   
- denormalize fields and nested fields √  
- denormalize belongs_to, has_many typed associations √    
- generate migration from denormalized model √   
- observe model changes and update denormalized model √  

## License  
see MIT-LICENSE.
