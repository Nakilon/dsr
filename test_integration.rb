require "minitest/autorun"
require_relative "lib/dsr"

require "digest"
describe :test do
  require "json"

  it :google2struct do
    unless File.exist? "temp.json"
      require "open-uri"
      File.write "temp.json", URI("https://storage.yandexcloud.net/gems.nakilon.pro/dsr/patent_imgf.json").open(&:read).tap{ |_| assert_equal "00b38499ce020c45657555759c508fb6", Digest::MD5.hexdigest(_) }
    end
    all = DSR.google2struct File.read "temp.json"
    assert_equal "d5b612125768413656fed71792d03c3c", Digest::MD5.hexdigest(all.to_json)

    all.shift
    all.reject! do |_|
      all.any? do |__|
        _.width * _.height < __.width * __.height &&
        (__.left..__.right).include?((_.left+_.right)/2) &&
        (__.top..__.bottom).include?((_.top+_.bottom)/2)
      end
    end
    all = all.sort_by(&:left).zip
    all.combination(2) do |l1, l2|
      next if l1.empty? || l2.empty?
      l1.push l2.shift if (l2.first.top..l2.first.bottom).include?((l1.last.top + l1.last.bottom) / 2) &&
                          (l1.last.top..l1.last.bottom).include?((l2.first.top + l2.first.bottom) / 2) &&
                          (l2.first.left - l1.last.right).abs <= (l1.last.height + l2.first.height) / 2
    end
    all = all.reject(&:empty?).sort_by{ |_,| _.top }.drop(2)
    all = all.sort_by{ |_,| _.left }.zip
    all.combination(2) do |l1, l2|
      next if l1.empty? || l2.empty?
      l1.push l2.shift if l1.map(&:last).map(&:right).max > l2.first.first.left
    end
    all = all.reject(&:empty?).each{ |_| _.sort_by!{ |_,| _.top } }
    all = all.map do |_|
      _.each_with_object([]) do |line, acc|
        row_index = all.first.count do |col1line|
          col1line.first.top <= (line.first.top + line.first.bottom) / 2
        end - 1
        acc[row_index] ||= []
        acc[row_index].push line
      end
    end.transpose
    assert_equal "b0f32d53472947d3ce6f33105741af52", Digest::MD5.hexdigest( all.drop(3).map do |_|
      _.map{ |_| _.flatten.map(&:text).join }.tap do |_|
        _[1] = _[1][/(?<=:OAC)[^:]+/].sub("174RV84R", "174R/V84R").
                                      sub("174GV84R", "174G/V84R").
                                      sub("V31GY41T", "V31G/Y41T").
                                      sub("174DV84R", "174D/V84R").split(?/).each do |s|
          s[0] = ?I if s[/\A174[D-R]\z/]
          s.replace "R100M" if "R100OM" == s
        end
      end
    end.to_json )
  end

  it "pdf2struct, find_all_by_text, select_intersecting_vertically_with, link" do
    all = DSR.pdf2struct File.new "enigma.pdf"
    assert_equal "616dcb7d27164632eb592d610c5d6f8f", Digest::MD5.hexdigest(all.to_json)
    assert_equal 2, all.size
    # TODO: assert map(&:size); download if needed

    all = all.flat_map do |texts|
      a = texts.find_all_by_text "Country of Origin"
      b = texts.find_all_by_text "Subtotal"
      next [] if a.empty? && b.empty?
      a.zip(b).flat_map do |country, subtotal|
        headers = texts.select_intersecting_vertically_with(country) + [country]
        DSR.subgraphs texts.select{ |_| _.top > country.bottom && _.bottom < subtotal.top } do |a, b|
          (a.top..a.bottom).include?((b.top+b.bottom)/2) || (b.top..b.bottom).include?((a.top+a.bottom)/2)
        end.map do |row|
          t = DSR.link headers, row, :horizontal, :index, "S1"
          [
            t[2][0].text,
            t[0][0].text.to_i,
            t[1][0].text.to_i,
            Rational(t[6][0].text),
            Rational(t[7][0].text),
          ]
        end
      end
    end
    assert_equal [
      ["Paeo L Sarah Bernardt",                  55, 960, 2.24, 2150.4],
      ["Alstroemeria Pink Dubai",                80,  50, 0.67, 33.5],
      ["Chame Un Early Nir",                     80,  25, 0.66, 16.5],
      ["Chr S Rossi Pink",                       55,  75, 0.34, 25.5],
      ["Chr T Chic White Ex",                    70,  80, 0.75, 60.0],
      ["Dec Bunch Nobilis White Band By 5 Bunch", 0,   5, 9.47, 47.35],
      ["Dec Euca Cinerea",                       80,   5, 4.63, 23.15],
      ["Di St Baltico",                          55,  40, 0.23,  9.2],
      ["Di St Doncel",                           60,  80, 0.31, 24.8],
      ["Di St Janeiro",                          65,  20, 0.26,  5.2],
      ["Dried Gossypium (katoen) 8 Bal",         70,   3, 1.34,  4.02],
      ["Eus G Rosi Yellow",                      72,  20, 0.94, 18.8],
      ["Eust G Alissa White",                    70,  40, 0.97, 38.8],
      ["Eust G Celeb Chrystal",                  72,  40, 0.95, 38.0],
      ["Ilex Ve Rode Bes",                      100,   5, 1.1,   5.5],
      ["Lim S Rosel Sun Birds",                  80,  25, 0.49, 12.25],
      ["Oxy Co Tan Pure Blu",                    60,  50, 0.36, 18.0],
      ["R Tr Clas Sensation Extra",              60,  30, 0.47, 14.1],
      ["R Tr Dinara",                            60,  30, 0.35, 10.5],
      ["R Tr Madam Bombastic",                   70,  40, 0.84, 33.6],
      ["R Tr Sun Trendsetter",                   70,  30, 0.2,   6.0],
      ["Skimmia Red Rubella Extra",              45,  10, 3.54, 35.4],
      ["Tu En Gemengd Pastel",                   38, 100, 0.31, 31.0],
      ["Tu En Royal Virgin Extra",               38, 150, 0.26, 39.0],
    ], all
  end

end
