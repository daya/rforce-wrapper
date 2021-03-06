require 'rforce'
require 'rforce-wrapper/utilities'
require 'rforce-wrapper/version'
require 'rforce-wrapper/exceptions/salesforce_fault_exception'
require 'rforce-wrapper/exceptions/invalid_environment_exception'
require 'rforce-wrapper/methods/core'
require 'rforce-wrapper/methods/describe'
require 'rforce-wrapper/methods/utility'
require 'rforce-wrapper/types'

module RForce
  module Wrapper
    class Connection
      include RForce::Wrapper::ApiMethods::CoreMethods
      include RForce::Wrapper::ApiMethods::DescribeMethods
      include RForce::Wrapper::ApiMethods::UtilityMethods

      # @return [RForce::Binding] the underlying `RForce::Binding` object.
      attr_reader :binding

      # Creates a new connect to the Salesforce API using the given email and
      # password or password+token combination and connects to the API.
      # Additional options can be specified. If a version of the Salesforce
      # API that is not supported by the gem is passed, a warning is issued.
      #
      # @param [String] email the email address of the account to log in with
      # @param [String] pass the password or password+token combo for the account
      # @param [Hash] options additional options for the connection
      # @option options [:live, :test] :environment the environment,
      #   defaults to `:live`
      # @option options [String] :version the version of the Salesforce API to
      #   use, defaults to `'21.0'`
      # @option options [Boolean] :wrap_results whether or not to wrap
      #   single-element results into an array, defaults to `true`
      # @raise [RForce::Wrapper::InvalidEnvironmentException] raised via
      #   `url_for_environment` if an invalid environment is passed
      # @see .url_for_environment
      def initialize(email, pass, options = {})
        options = {
          :environment  => :live,
          :version      => '21.0',
          :wrap_results => true
        }.merge(options)
        @wrap_results = options[:wrap_results]
        unless SF_API_VERSIONS.include? options[:version]
          message = "Version #{options[:version]} of the Salesforce Web " +
            "Services API is not supported by RForce-wrapper."
          Kernel.warn(message)
        end
        @binding = RForce::Binding.new Connection.url_for_environment(options[:environment], options[:version])
        @binding.login email, pass
      end

      # Returns the URL for the given environment type and version.
      #
      # @param [:live, :test] type the environment type
      # @param [String] version the version of the Salesforce API to use
      # @return [String] the URL for the given environment and version
      # @raise [RForce::Wrapper::InvalidEnvironmentException] raised if an
      #   invalid environment type is passed
      def self.url_for_environment(type, version)
        case type
        when :test
          "https://test.salesforce.com/services/Soap/u/#{version}"
        when :live
          "https://www.salesforce.com/services/Soap/u/#{version}"
        else
          raise InvalidEnvironmentException.new "Invalid environment type: #{type.to_s}"
        end
      end

      # Performs a SOAP API call via the underlying `RForce::Binding`
      # object. Raises an exception if a `Fault` is detected. Returns
      # the data portion of the result (wrapped in an `Array` if
      # `wrap_results` is true; see {#initialize}).
      #
      # @param [Symbol] method the API method to call
      # @param [Array, Hash, nil] params the parameters to pass to the API
      #   method. `RForce::Binding` expects either an `Array` or `Hash` to
      #   turn into SOAP arguments. Pass `nil`, `[]` or `{}` if the API
      #   call takes no parameters.
      # @return [Hash, Array, nil] a hash of the data portion of the result,
      #   wrapped in an array if `wrap_results` is true and the results are
      #   not already an array (indicating multiple results); see
      #   {#initialize}. If there is no data in the result, `nil` is returned.
      # @raise [RForce::Wrapper::SalesforceFaultException] indicates that
      #   a `Fault` was returned from the Salesforce API
      def make_api_call(method, params = nil)
        result = @binding.send method, params

        # Errors will result in result[:Fault] being set
        if result[:Fault]
          raise SalesforceFaultException.new result[:Fault][:faultcode], result[:Fault][:faultstring]
        end

        # If the result was successful, there will be a key: "#{method.to_s}Response".to_sym
        # which will contain the key :result
        result_field_name = method.to_s + "Response"
        if result[result_field_name.to_sym]
          data = result[result_field_name.to_sym][:result]
          @wrap_results ? Utilities.ensure_array(data) : data
        else
          nil
        end
      end
    end
  end
end
