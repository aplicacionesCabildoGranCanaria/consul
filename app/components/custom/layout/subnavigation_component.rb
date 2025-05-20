module Layout
    class SubnavigationComponent < ApplicationComponent
        attr_reader :menu
        def initialize(menu)
            @menu = menu
          end
    end
end

