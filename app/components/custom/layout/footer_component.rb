module Layout
    class FooterComponent < ApplicationComponent
         delegate :content_block, to: :helpers

        def render?
            !Rails.application.multitenancy_management_mode?
        end
        
    end
end
