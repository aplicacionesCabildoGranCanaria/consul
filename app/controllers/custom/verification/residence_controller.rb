require_dependency Rails.root.join("app", "controllers", "verification", "residence_controller").to_s


class Verification::ResidenceController

  def create
    begin
      @residence = Verification::Residence.new(residence_params.merge(user: current_user))
      if current_user.document_number
        @residence.document_number = current_user.document_number
        @residence.document_type = current_user.document_type
      end

      if @residence.save
        redirect_to verified_user_path, notice: t("verification.residence.create.flash.success")
      else
        render :new
      end
    rescue => e
      @residence.errors.add(:connection_error, true)
      logger.fatal "Residency Verification: #{e}"
      render :new
    end
  end

end
