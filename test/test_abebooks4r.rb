require 'helper'

class TestAbebooks4r < Test::Unit::TestCase
	
	ABE_ACCESS_KEY = ''  
  
	raise "Please specify set your ABE_ACCESS_KEY" if ABE_ACCESS_KEY.empty?
  
  
	Abebooks4r::Abe.configure do |options|    
		options[:clientkey] = ABE_ACCESS_KEY  	  
  	end
	
  	Abebooks4r::Abe.debug = false
	
	def test_abebooks_total_result_count
		resp = Abebooks4r::Abe.search(:author => 'Brad Ediger', :title => 'Advanced Rails')
		assert(resp.total_results == 43)
	end
	
	def test_abebooks_book_object
		resp = Abebooks4r::Abe.search(:author => 'Brad Ediger', :title => 'Advanced Rails')		
		assert(resp.books.first.get('title') == 'Advanced Rails')
		assert(resp.books.first.get('author') == 'Ediger, Brad')
	end	
end
