json.array!(@requirements) do |requirement|
  json.extract! requirement, :buy_num, :title, :specification
  json.url requirement_url(requirement, format: :json)
end
