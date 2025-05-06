require "street_address"
require "net/http"
require "json"

class AddressExtractor
  def self.generate_address_completion(text_body, model = "gpt-4.1-nano")
    url = URI("https://api.openai.com/v1/chat/completions")

    # Set the API parameters
    prompt =
      "" \
        "Format the following text into a valid USPS mailing address.
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

Input: #{text_body}" \
        ""
    max_tokens = 100 # The maximum number of tokens to generate
    temperature = 0.0 # Controls the randomness of the generated text
    json_params = {
      "model" => model,
      "messages" => [{ role: "user", content: prompt }],
      "max_tokens" => max_tokens,
      "temperature" => temperature
    }.to_json

    # Set the API headers
    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV["OPENAI_API_KEY"]}" # Replace with your OpenAI API key
    }

    # Send the API request
    puts "prompt: #{prompt}"
    response = Net::HTTP.post(url, json_params, headers)

    # Parse the API response
    data = JSON.parse(response.body)
    puts "resp: #{data}"

    raise "OpenAI API Error: #{data["error"]["message"]}" if data["error"]

    if !data["choices"] || data["choices"].empty?
      raise "No completion returned from OpenAI API"
    end

    data["choices"].map { |choice| choice["message"]["content"] }
  end

  def self.extract(text_body, model = "gpt-3.5-turbo")
    completions = generate_address_completion(text_body, model)
    lines = completions[0].strip.split("\n")
    name = lines[0].strip
    address_lines = lines[1..-1]

    # Join address lines with a comma for StreetAddress parsing
    address_text = address_lines.join(", ")
    Rails.logger.info("sendgrid extracted_address text: #{address_text}")

    address = StreetAddress::US.parse(address_text)
    Rails.logger.info("sendgrid extracted_address parsed: #{address}")

    [name, address]
  end
end
