class Management::Budgets::PrintInvestments::TableComponent < ApplicationComponent
  attr_reader :budgets

  def initialize(budgets)
    @budgets = budgets
  end
end
