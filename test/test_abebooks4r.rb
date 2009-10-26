require 'helper'

class TestAbebooks4r < Test::Unit::TestCase
	
	ABE_ACCESS_KEY = ''  
  
	raise "Please specify set your ABE_ACCESS_KEY" if ABE_ACCESS_KEY.empty?
  
  
	Abebooks4r::Abe.configure do |options|    
		options[:clientkey] = ABE_ACCESS_KEY  	  
  	end
	
  	#set a switch for debugging
  	Abebooks4r::Abe.debug = true
	
  	#test the result count from service
	def test_abebooks_total_result_count
		resp = Abebooks4r::Abe.search(:author => 'Brad Ediger', :title => 'Advanced Rails')
		assert(resp.total_results == 41) #this varies time to time
	end
	
	#test the composition of book obect returned
	def test_abebooks_book_object
		resp = Abebooks4r::Abe.search(:author => 'Brad Ediger', :title => 'Advanced Rails')		
		assert(resp.books.first.get('title') == 'Advanced Rails')
		assert(resp.books.first.get('author') == 'Ediger, Brad')
	end
	
	#test error detection on service response
	def test_abebooks_error
		resp = Abebooks4r::Abe.search(:authr => 'Brad Ediger', :title => 'Advanced Rails')
		assert(resp.has_error? == true)
	end	
end
