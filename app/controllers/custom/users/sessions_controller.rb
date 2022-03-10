require_dependency Rails.root.join("app", "controllers", "users", "sessions_controller").to_s

class Users::SessionsController < Devise::SessionsController

  private

  def verify_residence
    unless current_user.skip_verification?
      if current_user.residence_verified? && (!current_user.residence_verified_at || (Time.current - current_user.residence_verified_at > 180.days))
        residence = Verification::Residence.new(
            user: current_user,
            document_number: current_user.document_number,
            document_type: current_user.document_type,
            date_of_birth: current_user.date_of_birth,
            postal_code: current_user.postal_code,
            terms_of_service: true)

        if !residence.save
          residence.set_as_unverified
          lock = Lock.find_or_create_by!(user: current_user)
          lock.tries = 0
          lock.save!
        end
      end
    end
  end

  def after_sign_in_path_for(resource)
    verify_residence
    if !verifying_via_email? && resource.show_welcome_screen?
      welcome_path
    else
      super
    end
  end
end
