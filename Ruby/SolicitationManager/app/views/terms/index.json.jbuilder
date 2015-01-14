json.array!(@terms) do |term|
  json.extract! term, :buy_num, :title, :specification
  json.url term_url(term, format: :json)
end
