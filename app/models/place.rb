class Place 
  include ActiveModel::Model


  attr_accessor :id, :formatted_address, :location, :address_components


  def initialize(hash)
    @id = hash[:_id].to_s
    @address_components = []
    hash[:address_components].each { |e| @address_components << AddressComponent.new(e)} if hash[:address_components]
    @formatted_address = hash[:formatted_address]
    @location=Point.new(hash[:geometry][:geolocation])

  end

  def self.mongo_client
    Mongoid::Clients.default

  end

  def self.collection
    self.mongo_client['mongo_places']

  end

  def persisted?
    !@id.nil?
  end

  def self.load_all(input)

    file = File.open(input)
    json = file.read

    parsed = JSON.parse(json)


    Place.collection.insert_many(parsed)

  end 

  def self.find_by_short_name(name)

   Place.collection.find( { 'address_components.short_name' => name})
   

 end


 def self.to_places(input)

  pl = []
  input.each do |i|
    i = Place.new(i)
    pl << i
  end
  return pl


end


def self.find(ids)

  if ids.class == Place
    ids = BSON::ObjectId.from_string(ids.id.to_s)
  elsif ids.class == String
    ids = BSON::ObjectId.from_string(ids)
  else
    ids = ids
  end

  d = Place.collection.find(:_id=>ids).first
  if d.nil?
    return nil
  end
  return Place.new(d)

end


def self.all(offset=0, limit=0)



  result = collection.find.skip(offset)
  result = result.limit(limit) if !limit.nil? 
  places = []
  result.each do |r|
    places << Place.new(r)
  end
  return places

end



def destroy

  Place.collection.find(:_id=>BSON::ObjectId.from_string(@id)).delete_one()



end



def self.get_address_components(sort=0, offset=0, limit=0)

  q=[{:$project=> {:_id => 1, :address_components=> 1, :formatted_address => 1, 'geometry.geolocation'=> 1}},
   {:$unwind=>'$address_components'}]
   
   q.append({"$sort"=>sort}) if sort !=0
   q.append({"$skip"=>offset}) if offset !=0
   q.append({"$limit"=>limit}) if limit !=0
   a = Place.collection.find.aggregate(q)
   return a

 end


 def self.get_country_names


  q=[{:$project=> {:'address_components.long_name' => 1, 'address_components.types'=> 1}},
    {:$unwind=>'$address_components'},
    {:$unwind=>'$address_components.types'},
    {:$match=>{'address_components.types'=>'country'}},
    {:$group=>{:_id=>'$address_components.long_name'}}]
    
    
    
    an = Place.collection.find.aggregate(q)
    
    
    
    
    
    b = an.to_a.map {|h| h[:_id]}

  end


  def self.find_ids_by_country_code(country_code)

    q=[
      {:$match=>{'address_components.types'=>'country'}},
      {:$match=>{'address_components.short_name'=>country_code}},
      {:$project=> {:_id => 1}}
    ]

    
    an = Place.collection.find.aggregate(q)
    
    
    b = an.map {|h| h[:_id].to_s}
  end




  def self.create_indexes
    Place.collection.indexes.create_one({ 'geometry.geolocation' => "2dsphere" })
    

  end

  def self.remove_indexes
    Place.collection.indexes.drop_one({'geometry.geolocation'=> "2dsphere"})

  end






  def self.near(point, max_meters=nil)

    p = point.to_hash
    Place.collection.find('geometry.geolocation' => {:'$near'  => p,:'$maxDistance' => max_meters})


  end



  def near(maximum_distance=0)

    result = self.class.near(@location, maximum_distance) 
    self.class.to_places(result)

  end



  def photos(offset=0, limit=0)


   result = Photo.mongo_client.database.fs.find({'metadata.place'=>BSON::ObjectId.from_string(@id)}).skip(offset)
   result = result.limit(limit) if !limit.nil? 
   photos = []
   result.each{|i| photos << Photo.new(i)}
   return photos

 end

end




