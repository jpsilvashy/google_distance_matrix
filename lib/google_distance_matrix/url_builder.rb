module GoogleDistanceMatrix
  class UrlBuilder
    BASE_URL = "maps.googleapis.com/maps/api/distancematrix/json"
    DELIMITER = CGI.escape("|")
    MAX_URL_SIZE = 2048

    attr_reader :matrix
    delegate :configuration, to: :matrix

    def initialize(matrix)
      @matrix = matrix

      fail InvalidMatrix.new matrix if matrix.invalid?
    end

    def url
      @url ||= build_url
    end


    private

    def build_url

      setup_url = [protocol, BASE_URL, "?", get_params_string]

      if api_key?
        setup_url << configuration.key
      end

      url = setup_url.join

      if sign_url?
        url = GoogleBusinessApiUrlSigner.add_signature(url, configuration.google_business_api_private_key)
      end

      if url.length > MAX_URL_SIZE
        fail MatrixUrlTooLong.new url, MAX_URL_SIZE
      end

      url
    end

    def sign_url?
      configuration.google_business_api_client_id.present? and
      configuration.google_business_api_private_key.present?
    end

    def api_key?
      configuration.key.present?
    end

    def get_params_string
      params.to_a.map { |key_value| key_value.join("=") }.join("&")
    end

    def params
      places_to_param_config = {lat_lng_scale: configuration.lat_lng_scale}

      configuration.to_param.merge(
        origins: matrix.origins.map { |o| escape o.to_param(places_to_param_config) }.join(DELIMITER),
        destinations: matrix.destinations.map { |d| escape d.to_param(places_to_param_config) }.join(DELIMITER),
      )
    end

    def protocol
      configuration.protocol + "://"
    end

    def escape(string)
      CGI.escape string
    end
  end
end
