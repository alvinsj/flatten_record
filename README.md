# FlattenRecord

An ActiveRecord plugin that denormalizes your existing ActiveRecord models. 

It includes generation of migration, observing the save/destory on target model and changes the records accordingly. It provides an easier way to create denormalized models to be used in reporting.

## Example
    class DenormalizedOrderLineItem < ActiveRecord::Base
    	include FlattenRecord::Denormalize

    	denormalize :order do |order|
      		order.denormalize :customer
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

## Changes

#####v1   
_still in development_  
- denormalize fields and nested fields √  
- generate migration from denormalized model √   
- observe model changes and update denormalized model √  
- ...

## License  
see the MIT-LICENSE.
