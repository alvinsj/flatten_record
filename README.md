# FlattenRecord [![Code Climate](https://codeclimate.com/github/alvinsj/flatten_record.png)](https://codeclimate.com/github/alvinsj/flatten_record)  [![Build Status](https://travis-ci.org/alvinsj/flatten_record.png?branch=master)](https://travis-ci.org/alvinsj/flatten_record)

An ActiveRecord plugin that denormalizes your existing ActiveRecord models. 

It provides an easier way to create denormalized records to be used for reporting, includes generation of migration file. 

## Usage

Add gem dependency

    gem 'flatten_record'

Include module in your newly defined model

	include FlattenRecord::Flattener
	
### Define denormalization
    class DenormalizedOrder < ActiveRecord::Base
    	include FlattenRecord::Flattener

    	denormalize :order, {
      		include: { 
      		    # :belongs_to association
      			customer: {}
      		
      			# :has_many association, create multiple denormalized records  
      			line_items: {}
  			},
  			methods: {
          		# save methods defined in Normalized model
          		total_in_usd: :decimal 
          	},
          	compute: {
          		# compute methods defined in Denormalized model
          		line_items_sum: { type: :decimal, default: 0 } 
          	}
    	}

    	private
    	def compute_line_items_sum(order)
      		order.line_items.collect(&:total).inject(:+)
    	end
  	end
  	
  	class Order < ActiveRecord::Base
		def total_in_usd
			# calculation
		end
	end
  	
### Generate migration file
Generate migration file based on the definition

    $ rails generate flatten_record:migration denormalized_order
	  create  db/migrate/20140313034700_create_table_denormalized_orders.rb	    
Update definition and generate new migration file

    $ rails generate flatten_record:migration denormalized_order
    Warning. Table already exists: denormalized_orders
	Generating migration based on the difference..
	Add columns: d_line_items_description
      create  db/migrate/20140313034736_add_d_line_items_description_to_denormalized_orders.rb      

### Use denormalizer methods
Create record

	irb(main)> DenormalizedOrder.create_with(order)

Deleting record(s)

	irb(main)> DenormalizedOrder.destroy_with(order)

Update record(s)

	irb(main)> DenormalizedOrder.update_with(order)

## Design & Documentation  

Refer to the [wiki](https://github.com/alvinsj/flatten_record/wiki).
    
    
## Versions

#####v1  
- tree-based denormalization: nicer code & structure √ 
- new DSL + syntax √    
(Credit to [@scottharvey](https://github.com/scottharvey)'s issue [#6](https://github.com/alvinsj/flatten_record/issues/6))
- added :prefix option - use your own column prefix √  
- added :methods option - save normalized model's method √  
(Credit to [@scottharvey](https://github.com/scottharvey)'s idea)
- change to old :save option to :compute option √  
(Credit to [@scottharvey](https://github.com/scottharvey)'s idea)
- deprecate observer √  

#####v0   
- denormalize fields and nested fields √  
- denormalize belongs_to, has_many typed associations √    
- generate migration from denormalized model √   
- observe model changes and update denormalized model √  

## Contributors
- [@scottharvey](https://github.com/scottharvey)

## License  
see MIT-LICENSE.
