#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'

URL = 'http://phantom-metrics.herokuapp.com'

while line = STDIN.gets
  full_json = JSON.parse(line)
  data = full_json['@fields']['data']
  if data.has_key?('eventname')
    case data['eventname']
    when 'new_node'
      @uri = URI("#{URL}/metrics/total_vms")
      @req = Net::HTTP::Post.new(@uri.path)
      @req.set_form_data({})
    when 'new_domain'
      user = data['extra']['user']
      @uri = URI("#{URL}/metrics/new_domain")
      @req = Net::HTTP::Post.new(@uri.path)
      @req.set_form_data({ 'user' => user })
    else
      STDERR.puts "Unknown event #{data['eventname']}"
      next
    end

    @req.basic_auth ENV['METRICS_USERNAME'], ENV['METRICS_PASSWORD']

    begin
      response = Net::HTTP.start(@uri.host, @uri.port) do |http|
        http.request(@req)
      end

      if not response.kind_of? Net::HTTPSuccess
        STDERR.puts "POST failed: #{response.code}: #{response.message}"
      end
    rescue Exception => e 
      puts e.message 
      puts e.backtrace.inspect 
    end 
  end
end
