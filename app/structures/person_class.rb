class Person
 
  attr_reader :uni, :email, :full_name, :last_name, :first_name, :items_list
  attr_accessor :uni, :email, :full_name, :last_name, :first_name, :items_list
  
  def initialize
    @uni, @email, @full_name, @last_name, @first_name = nil
    @items_list = []
  end  
  
end