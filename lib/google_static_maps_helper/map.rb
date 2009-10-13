module GoogleStaticMapsHelper
  # Represents the map we are generating
  # It holds markers and iterates over them to build the URL
  # to be used in an image tag.
  class Map
    include Enumerable

    REQUIRED_OPTIONS = [:key, :size, :sensor]
    OPTIONAL_OPTIONS = [:center, :zoom, :size, :format, :maptype, :mobile, :language]
    
    attr_reader :options

    def initialize(options)
      validate_required_options(options)
      validate_options(options)

      @options = options
      @markers = []
    end

    def url
      raise BuildDataMissing, "We have to have markers or center and zoom set when url is called!" unless can_build?
      
      out = "#{API_URL}?"

      params = []
      options.each_pair do |key, value|
        params << "#{key}=#{URI.escape(value.to_s)}"
      end
      out += params.join('&')

      params = []
      grouped_markers.each_pair do |marker_options_as_url_params, markers|
        markers_locations = markers.map { |m| m.location_to_url }.join('|')
        params << "markers=#{marker_options_as_url_params}|#{markers_locations}"
      end
      out += "&#{params.join('&')}" unless params.empty?

      out
    end

    def grouped_markers
      inject(Hash.new {|hash, key| hash[key] = []}) do |groups, marker|
        groups[marker.options_to_url_params] << marker
        groups
      end
    end
    
    def <<(marker)
      @markers << marker
      @markers.uniq!
    end

    def each
      @markers.each {|m| yield(m)}
    end

    def empty?
      @markers.empty?
    end

    def length
      @markers.length
    end

    def method_missing(method, *args, &block)
      return options[method] if options.has_key? method
      super
    end
    

    private
    def can_build?
      !@markers.empty? || (options[:center] && options[:zoom])
    end

    def validate_required_options(options)
      missing_options = REQUIRED_OPTIONS - options.keys
      raise OptionMissing, "The following required options are missing: #{missing_options.join(', ')}" unless missing_options.empty?
    end

    def validate_options(options)
      invalid_options = options.keys - REQUIRED_OPTIONS - OPTIONAL_OPTIONS
      raise OptionNotExist, "The following options does not exist: #{invalid_options.join(', ')}" unless invalid_options.empty?
    end
  end
end
