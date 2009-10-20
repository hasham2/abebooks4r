#--
# Copyright (c) 2009 Hasham Malik
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require "cgi"
require "base64"
require "uri"
require "net/https"
require "hpricot"

module Abebooks4r
	
	class RequestError < StandardError; end
	
	class Abe
		
		@@options = {:clientkey => ''}	
		@@debug = false
		
		# Default service options
		def self.options
			@@options
		end
    
		# Set default service options
		def self.options=(opts)
			@@options = opts
		end
    
		# Get debug flag.
		def self.debug
			@@debug
		end
    
		# Set debug flag to true or false.
		def self.debug=(dbg)
			@@debug = dbg
		end
    
		def self.configure(&proc)
			raise ArgumentError, "Block is required." unless block_given?
			yield @@options
		end
		
		#search abe books web service for the book
		def self.search(params = {})
			url = self.prepare_url(params)
			log "Request URL: #{url}"
			res = Net::HTTP.get_response(url)
			unless res.kind_of? Net::HTTPSuccess
				raise Abebooks4r::RequestError, "HTTP Response: #{res.code} #{res.message}"
			end
			log "Response text: #{res.body}"
			Response.new(res)
		end
		
		
		# Response object returned after a REST call to Amazon service.
		class Response
			# XML input is in string format
			def initialize(xml)
				@doc = Hpricot(xml)
			end

			# Return Hpricot object.
			def doc
				@doc
			end      
      
			# Return true if response has an error.
			def has_error?
				#!(error.nil? || error.empty?)
			end

			# Return error message.
			def error
				#Element.get(@doc, "error/message")
			end
      
			# Return error code
			def error_code
				#Element.get(@doc, "error/code")
			end
      
			# Return error message.
			def is_success?
				     	      	      
			end     				                          
		end
		
		protected
		
		def self.log(s)
			return unless self.debug
			if defined? RAILS_DEFAULT_LOGGER
				RAILS_DEFAULT_LOGGER.error(s)
			elsif defined? LOGGER
				LOGGER.error(s)
			else
				puts s
			end
		end
		
		private
		
		def self.prepare_url(params)
			params = params.merge(self.options)
			url = URI.parse("http://search2.abebooks.com/search?" +
    	    	    	params.to_a.collect{|item| item.first + "=" + CGI::escape(item.last) }.join("&")
          		)
          		return url
		end	
	end	
end	