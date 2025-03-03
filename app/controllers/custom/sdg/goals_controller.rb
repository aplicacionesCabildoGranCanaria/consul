load Rails.root.join("app", "controllers", "sdg", "goals_controller.rb")

class SDG::GoalsController
  def index
    @goals = @goals.order(:code)
    @phases = SDG::Phase.accessible_by(current_ability).order(:kind)
  end
end
