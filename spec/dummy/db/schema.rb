# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "denormalized_bookings", :force => true do |t|
    t.integer  "order_id"
    t.string   "order_reference"
    t.string   "status"
    t.date     "order_completed_at"
    t.string   "contact_name"
    t.string   "agent_name"
    t.string   "tour_code"
    t.string   "tour_name"
    t.float    "number_of_days"
    t.string   "private_scheduled"
    t.date     "departure_date"
    t.integer  "pax"
    t.integer  "pax_adult"
    t.integer  "pax_child"
    t.string   "nationality"
    t.string   "lead_source"
    t.string   "lead_source_details"
    t.decimal  "value_thb",                      :precision => 12, :scale => 2, :default => 0.0, :null => false
    t.date     "deposit_paid_date"
    t.date     "paid_date"
    t.date     "last_update"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "value_usd",                      :precision => 12, :scale => 2, :default => 0.0, :null => false
    t.string   "contact_email"
    t.decimal  "deposit_amount_thb",             :precision => 12, :scale => 2, :default => 0.0, :null => false
    t.decimal  "additional_payments_amount_thb", :precision => 12, :scale => 2, :default => 0.0, :null => false
    t.decimal  "balance_amount_thb",             :precision => 12, :scale => 2, :default => 0.0, :null => false
    t.decimal  "single_supplement_thb",          :precision => 12, :scale => 2, :default => 0.0, :null => false
    t.decimal  "bike_hire_thb",                  :precision => 12, :scale => 2, :default => 0.0, :null => false
    t.decimal  "tour_cost_thb",                  :precision => 12, :scale => 2, :default => 0.0, :null => false
    t.date     "last_additional_payment_date"
    t.date     "balance_due_date"
    t.string   "primary_destination"
    t.string   "customer_name"
    t.string   "customer_category"
    t.string   "quote_number"
    t.string   "currency"
    t.decimal  "balance",                        :precision => 10, :scale => 0
    t.decimal  "total",                          :precision => 10, :scale => 0
  end

end
