json.array!(@solicitations) do |solicitation|
  json.extract! solicitation, :buy_num, :rev, :title, :buyer, :end_time, :set_aside_req, :location, :category, :subcategory, :naics, :fbo_solicitation, :recovery_act, :delivery, :bid_delivery_days, :repost_reason, :solicitation_num, :revised_at, :removed_at
  json.url solicitation_url(solicitation, format: :json)
end
