module RemoteTranslations
  module Llm
    class Client
      def call(fields_values, locale)
        fields_values.map do |text|
          request_translation(text, locale)
        end
      end

      private

        def context
          @context ||= ::Llm::Config.context
        end

        def chat
          @chat ||= context.chat(provider: llm_provider, model: llm_model)
        end

        def prompt
          @prompt ||= YAML.load_file("config/llm_prompts.yml", aliases: true)["remote_translation_prompt"]
        end

        def request_translation(text, locale)
          text_prompt = prompt % { input_text: text, output_locale: locale }
          chat.ask(text_prompt).content
        end

        def llm_provider
          Setting["llm.provider"].downcase.to_sym
        end

        def llm_model
          Setting["llm.model"]
        end
    end
  end
end
