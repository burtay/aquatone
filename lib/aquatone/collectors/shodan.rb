module Aquatone
  module Collectors
    class Shodan < Aquatone::Collector
      self.meta = {
        :name         => "Shodan",
        :author       => "Michael Henriksen (@michenriksen)",
        :description  => "Uses the Shodan API to find hostnames",
        :require_keys => ["shodan"]
      }

      API_BASE_URI         = "https://api.shodan.io/shodan".freeze
      API_RESULTS_PER_PAGE = 100.freeze
      PAGES_TO_PROCESS     = 10.freeze

      def run
        request_shodan_page
      end

      private

      def request_shodan_page(page=1)
        response = get_request(construct_uri("hostname:#{domain.name}", page))
        if response.code != 200
          failure(response.parsed_response["error"] || "Shodan API returned unexpected response code: #{response.code}")
        end
        return unless response.parsed_response["matches"]
        response.parsed_response["matches"].each do |match|
          next unless match["hostnames"]
          match["hostnames"].each do |hostname|
            add_host(hostname) if hostname.end_with?(".#{domain.name}")
          end
        end
        request_shodan_page(page + 1) if next_page?(page, response.parsed_response)
      end

      def construct_uri(query, page)
        "#{API_BASE_URI}/host/search?query=#{url_escape(query)}&page=#{page}&key=#{get_key('shodan')}"
      end

      def next_page?(page, body)
        page <= PAGES_TO_PROCESS && body["total"] && API_RESULTS_PER_PAGE * page < body["total"].to_i
      end
    end
  end
end
