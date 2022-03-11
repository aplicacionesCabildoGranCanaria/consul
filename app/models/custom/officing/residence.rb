require_dependency Rails.root.join("app", "models", "officing", "residence").to_s

class Officing::Residence

  def geozone
    if Setting["feature.red_sara_service"].present?
      nil
    else
      Geozone.find_by(census_code: district_code)
    end
  end

  private

    def retrieve_census_data
      @census_api_response = RedSara::RedSaraServiceCaller.new.call(
          document_type, document_number, date_of_birth, postal_code
      )
    end

    def residency_valid?
      @census_api_response.valid? && valid_year_of_birth?
    end

    def valid_year_of_birth?
      return true if Setting.force_presence_date_of_birth? || Setting["feature.red_sara_service"].present?

      @census_api_response.date_of_birth.year.to_s == year_of_birth.to_s
    end
end
