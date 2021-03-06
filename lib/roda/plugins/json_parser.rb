# frozen-string-literal: true

require 'json'

class Roda
  module RodaPlugins
    # The json_parser plugin parses request bodies in json format
    # if the request's content type specifies json. This is mostly
    # designed for use with JSON API sites.
    #
    # This only parses the request body as JSON if the Content-Type
    # header for the request includes "json".
    module JsonParser
      DEFAULT_ERROR_HANDLER = proc{|r| r.halt [400, {}, []]}
      DEFAULT_PARSER = JSON.method(:parse)

      OPTS = {}.freeze
      RodaPlugins.deprecate_constant(self, :OPTS)
      JSON_PARAMS_KEY = "roda.json_params".freeze
      RodaPlugins.deprecate_constant(self, :JSON_PARAMS_KEY)
      INPUT_KEY = "rack.input".freeze
      RodaPlugins.deprecate_constant(self, :INPUT_KEY)
      FORM_HASH_KEY = "rack.request.form_hash".freeze
      RodaPlugins.deprecate_constant(self, :FORM_HASH_KEY)
      FORM_INPUT_KEY = "rack.request.form_input".freeze
      RodaPlugins.deprecate_constant(self, :FORM_INPUT_KEY)

      # Handle options for the json_parser plugin:
      # :error_handler :: A proc to call if an exception is raised when
      #                   parsing a JSON request body.  The proc is called
      #                   with the request object, and should probably call
      #                   halt on the request or raise an exception.
      # :parser :: The parser to use for parsing incoming json.  Should be
      #            an object that responds to +call(str)+ and returns the
      #            parsed data.  The default is to call JSON.parse.
      # :include_request :: If true, the parser will be called with the request
      #                     object as the second argument, so the parser needs
      #                     to respond to +call(str, request)+.
      def self.configure(app, opts=RodaPlugins::OPTS)
        app.opts[:json_parser_error_handler] = opts[:error_handler] || app.opts[:json_parser_error_handler] || DEFAULT_ERROR_HANDLER
        app.opts[:json_parser_parser] = opts[:parser] || app.opts[:json_parser_parser] || DEFAULT_PARSER
        app.opts[:json_parser_include_request] = opts[:include_request] || app.opts[:json_parser_include_request]
      end

      module RequestMethods
        # If the Content-Type header in the request includes "json",
        # parse the request body as JSON.  Ignore an empty request body.
        def POST
          env = @env
          if post_params = (env["roda.json_params"] || env["rack.request.form_hash"])
            post_params
          elsif (input = env["rack.input"]) && content_type =~ /json/
            str = input.read
            input.rewind
            return super if str.empty?
            begin
              json_params = env["roda.json_params"] = parse_json(str)
            rescue
              roda_class.opts[:json_parser_error_handler].call(self)
            end
            env["rack.request.form_input"] = input
            json_params
          else
            super
          end
        end

        private

        def parse_json(str)
          args = [str]
          args << self if roda_class.opts[:json_parser_include_request]
          roda_class.opts[:json_parser_parser].call(*args)
        end
      end
    end

    register_plugin(:json_parser, JsonParser)
  end
end
