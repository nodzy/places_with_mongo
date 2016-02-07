class Photo
  include ActiveModel::Model
  attr_accessor :id, :location, :contents, :place




  def initialize(params={})

  if params[:_id]  #hash came from GridFS
    @id=params[:_id].to_s
    @location=params[:metadata].nil? ? nil : Point.new(params[:metadata][:location])
    @place=params[:metadata].nil? ? nil : params[:metadata][:place]
    
  else              
    @id=params[:id]
    @location=Point.new(params[:location])
    @place=params[:place]
    
  end

end




def self.mongo_client
  Mongoid::Clients.default

end


def persisted?

  !@id.nil?
end



def save
  description = {}
  description[:metadata] = {}
  if !persisted?
    gps = EXIFR::JPEG.new(@contents).gps
    @contents.rewind
    @location = Point.new(:lng => gps.longitude, :lat => gps.latitude)
    description[:metadata][:place] = @place
    description[:metadata][:location] = @location.to_hash
    @contents.rewind
    description[:content_type] = "image/jpeg"

    grid_file = Mongo::Grid::File.new(@contents.read, description)
    id = self.class.mongo_client.database.fs.insert_one(grid_file)
    @id = id.to_s
    @id
  else
    description[:metadata][:location] = @location.to_hash
    description[:metadata][:place] = @place
    self.class.mongo_client.database.fs.find(:_id=> BSON::ObjectId.from_string(@id)).update_one(description)

  end
end





def self.all(offset=0, limit=0)
  result = self.mongo_client.database.fs.find.skip(offset)
  result = result.limit(limit) if !limit.nil? 
  photos = []
  result.map do |doc| 
    photos << Photo.new(doc)


  end
  return photos
end


def self.find(id)

  res = self.mongo_client.database.fs.find({:_id=> BSON::ObjectId.from_string(id)}).first
  photo = Photo.new(res) if res
end





def contents

  f= self.class.mongo_client.database.fs.find_one({:_id => BSON::ObjectId(self.id)})

  if f

    buffer = ""

    f.chunks.reduce([]) do |x,chunk|

      buffer << chunk.data.data

    end



    return buffer

  end

end

def destroy

  self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(@id)).delete_one

end



def find_nearest_place_id(maximum_distance)

  if result = Place.near(@location, maximum_distance) 
    result.limit(1).projection(:_id=>1).each {|r| result=r} 
    return result[:_id]
  else

    return 0

  end



end

def place
  if !@place.nil?
    Place.find(@place)
  end
end  

def place=(place)
  if place.class == Place
    @place = BSON::ObjectId.from_string(place.id.to_s)
  elsif place.class == String
    @place = BSON::ObjectId.from_string(place)
  else
    @place = place
  end
end



def self.find_photos_for_place(id)
  

 
  f = self.mongo_client.database.fs.find('metadata.place' => BSON::ObjectId.from_string(id))
end

end





