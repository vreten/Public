json.array!(@items) do |item|
  json.extract! item, :buy_num, :item_num, :description, :qty, :unit, :option, :period_of_performance
  json.url item_url(item, format: :json)
end
