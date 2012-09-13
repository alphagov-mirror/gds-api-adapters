require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentApi < GdsApi::Base
  include GdsApi::ExceptionHandling

  def sections
    get_json!("#{base_url}/tags.json?type=section")
  end

  def with_tag(tag)
    get_json!("#{base_url}/with_tag.json?tag=#{tag}&include_children=1")
  end

  def local_authority(snac_code)
    snac_code = CGI.escape(snac_code)
    get_json("#{base_url}/local_authorities/#{snac_code}.json")
  end

  def local_authorities_by_name(name)
    name = CGI.escape(name)
    get_json!("#{base_url}/local_authorities.json?name=#{name}")
  end

  def local_authorities_by_snac_code(snac_code)
    snac_code = CGI.escape(snac_code)
    get_json!("#{base_url}/local_authorities.json?snac_code=#{snac_code}")
  end

  private
    def base_url
      endpoint
    end
end
