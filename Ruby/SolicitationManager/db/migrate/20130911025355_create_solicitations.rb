class CreateSolicitations < ActiveRecord::Migration
  def change
    create_table :solicitations do |t|
      t.string :buy_num
      t.string :rev
      t.string :title
      t.string :buyer
      t.string :end_time
      t.string :set_aside_req
      t.string :location
      t.string :category
      t.string :subcategory
      t.string :naics
      t.string :fbo_solicitation
      t.string :recovery_act
      t.string :delivery
      t.string :bid_delivery_days
      t.string :repost_reason
      t.string :solicitation_num
      t.string :revised_at
      t.string :removed_at

      t.timestamps
    end
  end
end
