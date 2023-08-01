module DSR

  Struct = ::Struct.new :text, :left, :bottom, :right, :top, :width, :height
  private_constant :Struct

  def self.google2struct json
    require "json"
    JSON.load(json).tap do |json|
      require "nakischema"
      Nakischema.validate json, {
        hash_req: {
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
        },
        hash_opt: {
          "localizedObjectAnnotations" => Array,
        }
      }
    end["textAnnotations"].map do |text|
      Struct.new text["description"],
                 text["boundingPoly"]["vertices"].map{ |_| _["x"] }.min,
                 text["boundingPoly"]["vertices"].map{ |_| _["y"] }.max,
                 text["boundingPoly"]["vertices"].map{ |_| _["x"] }.max,
                 text["boundingPoly"]["vertices"].map{ |_| _["y"] }.min,
                 text["boundingPoly"]["vertices"].map{ |_| _["x"] }.max - text["boundingPoly"]["vertices"].map{ |_| _["x"] }.min,
                 text["boundingPoly"]["vertices"].map{ |_| _["y"] }.max - text["boundingPoly"]["vertices"].map{ |_| _["y"] }.min
    end
  end

  class Texts < Array
    def find_all_by_text text
      self.class.new select{ |_| text == _.text }
    end
    def select_intersecting_vertically_with item
      self.class.new (self-[item]).select{ |_| _.top >= item.bottom && _.bottom <= item.top }
    end
  end
  private_constant :Texts
  def self.link headers, array, direction, alignment, *priority
    l, r = case direction
    when :horizontal ; %i{ left right }
    when :vertical ; %i{ top bottom }
    else ; fail "invalid direction"
    end
    headers = headers.sort_by(&l).map(&:dup)
    headers.each_cons(2){ |a, b| a[r], b[l] = [a[r], b[l]].max, [a[r], b[l]].min }
    headers.first[l] = -Float::INFINITY
    headers.last[r] = +Float::INFINITY
    headers.unshift headers.delete_at headers.index{ |_| priority.include? _.text }   # TODO: document/explain this
    array.sort_by(&l).each_with_object([]) do |cell, a|
      i = headers.public_send(alignment){ |_| (_[l].._[r]).include?((cell[l]+cell[r])/2) }
      a[i] ||= []
      a[i] << cell
    end
  end
  def self.pdf2struct object
    require "hexapdf"
    processor = Class.new HexaPDF::Content::Processor do
      attr_reader :texts
      def initialize _
        super
        @texts = Texts.new
      end
      def show_text str
        boxes = decode_text_with_positioning str
        @texts.push Struct.new boxes.string,
          *boxes.lower_left,
          *boxes.upper_right,
          boxes.upper_right[0] - boxes.lower_left[0],
          boxes.lower_left[1] - boxes.upper_right[1]
      end
    end
    HexaPDF::Document.new(io: object).pages.map do |page|
      processor.new(page).tap(&page.method(:process_contents)).texts
    end
  end

  def self.subgraphs data
    data.zip.tap do |array|
      (0...data.size).each do |i|
        (0...i).to_a.select do |j|
          array[i].product(array[j]).any?{ |i,j| yield i,j }
        end.each do |j|
          array[i].concat array[j]
          array[j].clear
        end
      end
    end.reject &:empty?
  end

end
