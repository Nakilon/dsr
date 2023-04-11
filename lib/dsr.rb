module DSR

  Struct = ::Struct.new :text, :left, :bottom, :right, :top, :width, :height
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
  def self.link headers, row, *priority
    headers = headers.sort_by(&:left).map(&:dup)
    headers.each_cons(2){ |a, b| a.right, b.left = [a.right, b.left].max, [a.right, b.left].min }
    headers.first.left = -Float::INFINITY
    headers.last.right = +Float::INFINITY
    headers.unshift headers.delete_at headers.index{ |_| priority.include? _.text }
    row.sort_by(&:left).each_with_object({}) do |cell, h|
      k = headers.find{ |_| (_.left.._.right).include?((cell.left+cell.right)/2) }.text
      h[k] ||= []
      h[k] << cell.text
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

end
