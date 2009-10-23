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
			Response.new(res.body)
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
			
			# Return an array of Abebooks4r::Element item objects.
			def books
				unless @books
					@books = (@doc/"book").collect {|item| Element.new(item)}
				end
				@books
			end
			
			# Return total results.
			def total_results
				unless @total_results
					@total_results = (@doc/"resultcount").inner_html.to_i
				end
				@total_results		     	      	      
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
				params.to_a.collect{|item| item.first.id2name + "=" + CGI::escape(item.last) }.join("&")
          		)
          		return url
		end	
	end
	
	# Internal wrapper class to provide convenient method to access Hpricot element value.
	class Element
	
		# Pass Hpricot::Elements object
		def initialize(element)
			@element = element
		end

		# Returns Hpricot::Elments object    
		def elem
			@element
		end
    
		# Find Hpricot::Elements matching the given path. Example: element/"author".
		def /(path)
			elements = @element/path
			return nil if elements.size == 0
			elements
		end
    
		# Find Hpricot::Elements matching the given path, and convert to Abebooks4r::Element.
		# Returns an array Abebooks4r::Elements if more than Hpricot::Elements size is greater than 1.
		def search_and_convert(path)
			elements = self./(path)
			return unless elements
			elements = elements.map{|element| Element.new(element)}
			return elements.first if elements.size == 1
			elements
		end

		# Get the text value of the given path, leave empty to retrieve current element value.
		def get(path='')
			Element.get(@element, path)
		end
    
		# Get the unescaped HTML text of the given path.
		def get_unescaped(path='')
			Element.get_unescaped(@element, path)
		end
    
		# Get the array values of the given path.
		def get_array(path='')
			Element.get_array(@element, path)
		end

		# Get the children element text values in hash format with the element names as the hash keys.
		def get_hash(path='')
			Element.get_hash(@element, path)
		end

		# Similar to #get, except an element object must be passed-in.
		def self.get(element, path='')
			return unless element
			result = element.at(path)
			result = result.inner_html if result
			result
		end
    
		# Similar to #get_unescaped, except an element object must be passed-in.    
		def self.get_unescaped(element, path='')
			result = get(element, path)
			CGI::unescapeHTML(result) if result
		end

		# Similar to #get_array, except an element object must be passed-in.
		def self.get_array(element, path='')
			return unless element
      
			result = element/path
			if (result.is_a? Hpricot::Elements) || (result.is_a? Array)
				parsed_result = []
				result.each {|item|
					parsed_result << Element.get(item)
				}
				parsed_result
			else
				[Element.get(result)]
			end
        	end

        	# Similar to #get_hash, except an element object must be passed-in.
        	def self.get_hash(element, path='')
        		return unless element
    
        		result = element.at(path)
        		if result
        			hash = {}
        			result = result.children
        			result.each do |item|
        				hash[item.name.to_sym] = item.inner_html
        			end 
        			hash
        		end
        	end
    
        	def to_s
        		elem.to_s if elem
        	end
        end	
end	