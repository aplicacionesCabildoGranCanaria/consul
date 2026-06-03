module Layout
    class SubnavigationComponent < ApplicationComponent
        attr_reader :menu
        delegate :content_block, :layout_menu_link_to, to: :helpers

        def initialize(menu = nil)
            @menu = menu
        end

        def render?
            !Rails.application.multitenancy_management_mode?
        end
        
    end
end

