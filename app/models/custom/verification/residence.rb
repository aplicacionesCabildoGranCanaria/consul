require_dependency Rails.root.join("app", "models", "verification", "residence").to_s

class Verification::Residence
  validate :local_postal_code
  validate :local_residence

  def local_postal_code
    errors.add(:postal_code, I18n.t("verification.residence.new.error_not_allowed_postal_code")) unless valid_postal_code?
  end

  def local_residence
    return if errors.any?

    unless residency_valid?
      errors.add(:local_residence, false)
      store_failed_attempt
      Lock.increase_tries(user)
    end
  end

  def set_as_unverified
    user.update(
        residence_verified_at: nil,
        level_two_verified_at: nil,
        verified_at: nil
    )
  end

  def save
    return false unless valid?

    user.take_votes_if_erased_document(document_number, document_type)

    user.update(document_number:       document_number,
                document_type:         document_type,
                geozone:               geozone,
                date_of_birth:         date_of_birth.in_time_zone.to_datetime,
                gender:                gender,
                residence_verified_at: Time.current,
                level_two_verified_at: Time.current,
                verified_at:           Time.current,
                postal_code:           postal_code)
  end

  def document_number_uniqueness
    errors.add(:document_number, I18n.t("errors.messages.taken")) if User.active.where(
        ["document_number = ? and id != ?", document_number, user.id]
    ).any?
  end


  def geozone
    if Setting["feature.red_sara_service"].present?
      return nil
    end
    Geozone.find_by(census_code: district_code)
  end

  private

    def valid_postal_code?
      postal_code =~ /^35/
    end

    def retrieve_census_data
      @census_data = RedSara::RedSaraServiceCaller.new.call(
          document_type, document_number, date_of_birth, postal_code
      )
    end
end
