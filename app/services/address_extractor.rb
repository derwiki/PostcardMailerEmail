require 'street_address'
require 'net/http'
require 'json'

class AddressExtractor
    def self.extract(text_body)
        # TODO: use gpt-4o-mini
        url = URI("https://api.openai.com/v1/chat/completions")

        # Set the API parameters
        model = "gpt-3.5-turbo"  # The GPT model to use
        prompt = "Format the following as a valid mailing address for USPS: #{text_body}"  # The text prompt to generate completions for
        max_tokens = 100  # The maximum number of tokens to generate
        temperature = 0.0  # Controls the randomness of the generated text
        json_params = {
          "model" => model,
          "messages" => [{"role": "user", "content": prompt}],
          "max_tokens" => max_tokens,
          "temperature" => temperature
        }.to_json
  
        # Set the API headers
        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['OPENAI_API_KEY']}"  # Replace with your OpenAI API key
        }
  
        # Send the API request
        puts "prompt: #{prompt}"
        #Rails.logger.info("sendgrid extracted_address json_params: #{json_params}")
        response = Net::HTTP.post(url, json_params, headers)
  
        # Parse the API response
        data = JSON.parse(response.body)
        puts "resp: #{data}"
        completions = data["choices"].map { |choice| choice["message"]["content"] }
        #Rails.logger.info("sendgrid extracted_address completions: #{completions}")
        lines = completions[0].strip.split("\n")
        lines.each_with_index do |line, index|
          Rails.logger.info("sendgrid extracted_address line #{index}: #{line}")
        end
        oneline_address = lines[1..-1].join(',')
        Rails.logger.info("sendgrid extracted_address oneline_address #{index}: #{line}")
        address = StreetAddress::US.parse(oneline_address)
        [lines[0].strip, address]
    end
end