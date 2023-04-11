module DSR
  Struct = Struct.new :text, :left, :top, :right, :bottom, :width, :height
  private_constant :Struct
  def self.google2struct json
    require "json"
    JSON.load(json).tap do |json|
      require "nakischema"
      Nakischema.validate json, { hash: {
        "cropHintsAnnotation" => Hash,
        "fullTextAnnotation" => Hash,
        "imagePropertiesAnnotation" => Hash,
        "labelAnnotations" => Array,
        "safeSearchAnnotation" => Hash,
        "textAnnotations" => { each: {
          hash_req: {
            "boundingPoly" => { hash: {
              "vertices" => { size: 4..4, each: { hash: { "x" => Integer, "y" => Integer } } },
            } },
            "description" => /\A\S(.*\S)?\z/m,
          },
          hash_opt: {
            "locale" => /\A\S(.*\S)?\z/m,
          },
        } },
      } }
    end["textAnnotations"].map do |text|
      Struct.new text["description"],
                 text["boundingPoly"]["vertices"].map{ |_| _["x"] }.min,
                 text["boundingPoly"]["vertices"].map{ |_| _["y"] }.min,
                 text["boundingPoly"]["vertices"].map{ |_| _["x"] }.max,
                 text["boundingPoly"]["vertices"].map{ |_| _["y"] }.max,
                 text["boundingPoly"]["vertices"].map{ |_| _["x"] }.max - text["boundingPoly"]["vertices"].map{ |_| _["x"] }.min,
                 text["boundingPoly"]["vertices"].map{ |_| _["y"] }.max - text["boundingPoly"]["vertices"].map{ |_| _["y"] }.min
    end
  end
end
