# spec/support/red_sara_helpers.rb

module RedSaraMock
  def mock_red_sara_response(valid: true, postal_code: "35001", date_of_birth: Date.new(1980, 12, 31), district_code: "01", gender: "male")
    census_data = double(
      valid?: valid,
      postal_code: postal_code,
      date_of_birth: date_of_birth,
      district_code: district_code,
      gender: gender
    )

    allow_any_instance_of(RedSara::RedSaraServiceCaller)
      .to receive(:call)
      .and_return(census_data)

    census_data
  end
end

RSpec.configure do |config|
  config.include RedSaraMock
end