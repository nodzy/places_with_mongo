class Point

attr_accessor :latitude, :longitude

def initialize(hash)

if hash

if hash[:type] #in GeoJSON Point format

@longitude = hash[:coordinates][0]

@latitude = hash[:coordinates][1]

else #in legacy format

@latitude = hash[:lat]

@longitude = hash[:lng]

end

end

end

def to_hash

{:type=>'Point', :coordinates=>[@longitude,@latitude]}

end

end