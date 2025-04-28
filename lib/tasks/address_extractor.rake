namespace :address do
  desc "Test address extraction with a given input and optional model. Usage: ADDRESS='123 Main St, Boston, MA' MODEL=gpt-3.5-turbo rake address:extract"
  task extract: :environment do
    input = ENV['ADDRESS']
    model = ENV['MODEL'] || "gpt-3.5-turbo"

    if input.nil? || input.empty?
      puts "Please provide an input address using the ADDRESS environment variable."
      puts "Usage: ADDRESS='123 Main St, Boston, MA' MODEL=gpt-3.5-turbo rake address:extract"
      exit
    end

    puts "\nTesting address extraction with:"
    puts "Input: #{input}"
    puts "Model: #{model}"
    puts "\nResults:"

    begin
      name, address = AddressExtractor.extract(input, model)
      puts "\nExtracted Name: #{name}"
      puts "Extracted Address:"
      puts "  Street: #{[address.number, address.street, address.street_type].compact.join(' ')}"
      puts "  City: #{address.city}"
      puts "  State: #{address.state}"
      puts "  ZIP: #{address.postal_code}"
    rescue => e
      puts "\nError occurred:"
      puts e.message
      puts e.backtrace
    end
  end

  desc "Test raw address completion with a given input and optional model. Usage: ADDRESS='123 Main St, Boston, MA' MODEL=gpt-3.5-turbo rake address:generate_address_completion"
  task generate_address_completion: :environment do
    input = ENV['ADDRESS']
    model = ENV['MODEL'] || "gpt-3.5-turbo"

    if input.nil? || input.empty?
      puts "Please provide an input address using the ADDRESS environment variable."
      puts "Usage: ADDRESS='123 Main St, Boston, MA' MODEL=gpt-3.5-turbo rake address:generate_address_completion"
      exit
    end

    puts "\nTesting address completion with:"
    puts "Input: #{input}"
    puts "Model: #{model}"
    puts "\nResults:"

    begin
      result = AddressExtractor.generate_address_completion(input, model)
      puts "\nGenerated Address:"
      puts result[0]
    rescue => e
      puts "\nError occurred:"
      puts e.message
      puts e.backtrace
    end
  end
end 