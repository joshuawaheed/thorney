require 'coveralls'
require 'simplecov'
require 'vcr'
require 'webmock/rspec'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
 Coveralls::SimpleCov::Formatter,
 SimpleCov::Formatter::HTMLFormatter
])

SimpleCov.start 'rails' do
  add_filter 'spec'
end

# URIs that appear frequently
parliament_uri = 'http://localhost:3030'
bandiera_uri   = 'http://localhost:5000'
opensearch_uri = 'https://api.parliament.uk/search/description'
hybrid_bills_uri = 'http://localhost:5050'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  config.default_cassette_options = {
      # record: :new_episodes
      record: :once
  }

  # Create a simple matcher which will 'filter' any request URIs on the fly
  config.register_request_matcher :filtered_uri do |request_1, request_2|
    parliament_match   = request_1.uri.sub(ENV['PARLIAMENT_BASE_URL'], parliament_uri) == request_2.uri.sub(ENV['PARLIAMENT_BASE_URL'], parliament_uri) if ENV['PARLIAMENT_BASE_URL']
    bandiera_match     = request_1.uri.sub(ENV['BANDIERA_URL'], bandiera_uri) == request_2.uri.sub(ENV['BANDIERA_URL'], bandiera_uri) if ENV['BANDIERA_URL']
    opensearch_match   = request_1.uri.sub(ENV['OPENSEARCH_DESCRIPTION_URL'], opensearch_uri) == request_2.uri.sub(ENV['OPENSEARCH_DESCRIPTION_URL'], opensearch_uri) if ENV['OPENSEARCH_DESCRIPTION_URL']
    hybrid_bills_match = request_1.uri.sub(ENV['HYBRID_BILL_API_BASE_URL'], hybrid_bills_uri) == request_2.uri.sub(ENV['HYBRID_BILL_API_BASE_URL'], hybrid_bills_uri) if ENV['HYBRID_BILL_API_BASE_URL']

    parliament_match || bandiera_match || opensearch_match || hybrid_bills_match
  end

  config.default_cassette_options = { match_requests_on: [:method, :filtered_uri] }

  # Dynamically filter our sensitive information
  config.filter_sensitive_data('<AUTH_TOKEN>')   { ENV['PARLIAMENT_AUTH_TOKEN'] }       if ENV['PARLIAMENT_AUTH_TOKEN']
  config.filter_sensitive_data('<AUTH_TOKEN>')   { ENV['OPENSEARCH_AUTH_TOKEN'] }       if ENV['OPENSEARCH_AUTH_TOKEN']
  config.filter_sensitive_data(parliament_uri)   { ENV['PARLIAMENT_BASE_URL'] }         if ENV['PARLIAMENT_BASE_URL']
  config.filter_sensitive_data(bandiera_uri)     { ENV['BANDIERA_URL'] }                if ENV['BANDIERA_URL']
  config.filter_sensitive_data(opensearch_uri)   { ENV['OPENSEARCH_DESCRIPTION_URL'] }  if ENV['OPENSEARCH_DESCRIPTION_URL']
  config.filter_sensitive_data(hybrid_bills_uri) { ENV['HYBRID_BILL_API_BASE_URL'] }    if ENV['HYBRID_BILL_API_BASE_URL']

  # Dynamically filter n-triple data
  config.before_record do |interaction|
    should_ignore = ['_:node', '^^<http://www.w3.org/2001/XMLSchema#date>', '^^<http://www.w3.org/2001/XMLSchema#dateTime>', '^^<http://www.w3.org/2001/XMLSchema#integer>']

    # Check if content type header exists and if it includes application/n-triples
    if interaction.response.headers['Content-Type'] && interaction.response.headers['Content-Type'].include?('application/n-triples')
      # Split our data by line
      lines = interaction.response.body.split("\n")

      # How many times have we seen a predicate?
      predicate_occurrances = Hash.new(1)

      # Iterate over each line, decide if we need to filter it.
      lines.each do |line|
        next if should_ignore.any? { |condition| line.include?(condition) }
        next unless line.include?('"')

        # require 'pry'; binding.pry
        # Split on '> <' to get a Subject and Predicate+Object split
        subject, predicate_and_object = line.split('> <')

        # Get the actual object
        predicate, object = predicate_and_object.split('> "')

        # Get the last part of a predicate URI
        predicate_type = predicate.split('/').last

        # Get the number of times we've seen this predicate
        occurrance = predicate_occurrances[predicate_type]
        predicate_occurrances[predicate_type] = predicate_occurrances[predicate_type] + 1

        # Try and build a new object value based on the predicate
        new_object = "#{predicate_type} - #{occurrance}\""

        # Replace the object value
        index = object.index('"')

        object[0..index] = new_object if index

        new_line = "#{subject}> <#{predicate}> \"#{object}"
        config.filter_sensitive_data(new_line) { line }
      end
    end
  end
end
# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
=begin
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
=end

  config.before(:each) do
    allow(BANDIERA_CLIENT).to receive(:enabled?).and_return(false)
  end
end
