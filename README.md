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
      		order.save :order_sum, :decimal
    	end

    	private
    	def _save_order_sum(order)
      		order_sum = order.line_items.inject(0){|sum, i| sum += i.total }
    	end
  	end

## Changes

_still in alpha_  


## License  
see the MIT-LICENSE file.