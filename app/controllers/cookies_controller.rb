class CookiesController < ApplicationController
    skip_authorization_check only: :accept

    def accept
        cookies[:cookies_accepted] = { value: true}
        head :ok
    end
end
