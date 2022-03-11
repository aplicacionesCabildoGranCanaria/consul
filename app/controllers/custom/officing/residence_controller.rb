require_dependency Rails.root.join("app", "controllers", "officing", "residence_controller").to_s

class Officing::ResidenceController

  def create
    begin
      @residence = Officing::Residence.new(residence_params.merge(officer: current_user.poll_officer))
      if @residence.save
        redirect_to new_officing_voter_path(id: @residence.user.id), notice: t("officing.residence.flash.create")
      else
        render :new
      end
    rescue
      @residence.errors.add(:connection_error, true)
      logger.fatal "Residency Verification: #{e}"
      render :new
    end
  end

end
