Given /^the following resources posted by "(.*?)":$/ do |provider,resource_table|
  resource_table.hashes.each do |r|
    p = User.find_by_email(provider)
    p.resources.create(:name => r['name'], :start_at => r['start_at'],:end_at => r['end_at'])
  end
end