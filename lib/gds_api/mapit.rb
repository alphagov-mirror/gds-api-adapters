require_relative "base"
require_relative "exceptions"

class GdsApi::Mapit < GdsApi::Base
  def location_for_postcode(postcode)
    response = get_json("#{base_url}/postcode/#{CGI.escape postcode}.json")
    Location.new(response) unless response.nil?
  end

  def areas_for_type(type)
    get_json("#{base_url}/areas/#{type}.json")
  end

  def area_for_code(code_type, code)
    get_json("#{base_url}/code/#{code_type}/#{code}.json")
  end

  class Location
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def lat
      @response["wgs84_lat"]
    end

    def lon
      @response["wgs84_lon"]
    end

    def areas
      @response["areas"].map { |_i, area| OpenStruct.new(area) }
    end

    def postcode
      @response["postcode"]
    end

    def country_name
      @response["country_name"]
    end
  end

private

  def base_url
    endpoint
  end
end
