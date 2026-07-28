module Layout
    class FooterComponent < ApplicationComponent
         delegate :content_block, to: :helpers

        def render?
            !Rails.application.multitenancy_management_mode?
        end

        def footer_legal_content_block
            content_block("footer_legal")
        end
        
    end
end
