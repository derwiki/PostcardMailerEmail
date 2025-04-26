require 'street_address'
require 'net/http'
require 'json'

class AddressExtractor
    def self.extract(text_body, model = "gpt-3.5-turbo")
        url = URI("https://api.openai.com/v1/chat/completions")

        # Set the API parameters
        prompt = """Format the following text into a valid USPS mailing address.
Output format should be:
Line 1: Name
Line 2: Street address (including apt/suite/unit)
Line 3: City, State ZIP

Examples:
Input: John Smith at 123 Main Street Apt 4B, Boston Massachusetts
Output:
John Smith
123 Main Street Apt 4B
Boston, MA 02108

Input: Sarah Johnson works at 456 Corporate Plaza Suite 789 in San Francisco CA 94105
Output:
Sarah Johnson
456 Corporate Plaza Suite 789
San Francisco, CA 94105

Input: Bob Wilson 789 Rural Route 2 Box 45 Little Rock Arkansas
Output:
Bob Wilson
789 Rural Route 2 Box 45
Little Rock, AR 72201

Input: #{text_body}"""
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
        Rails.logger.info("sendgrid extracted_address oneline_address: #{oneline_address}")
        address = StreetAddress::US.parse(oneline_address)
        Rails.logger.info("sendgrid extracted_address address: #{address}")
        [lines[0].strip, address]
    end
end