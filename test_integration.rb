require "minitest/autorun"
require_relative "lib/dsr"

require "digest"
describe :test do

  def check all
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

    require "yaml"
    assert_equal "dcb8653ccdcb2eee288926d3fb42469a", Digest::MD5.hexdigest( YAML.dump( all.drop(3).map do |_|
      _.map{ |_| _.flatten.map(&:text).join }.tap do |_|
        _[1] = _[1][/(?<=:OAC)[^:]+/].sub("174RV84R", "174R/V84R").
                                      sub("174GV84R", "174G/V84R").
                                      sub("V31GY41T", "V31G/Y41T").
                                      sub("174DV84R", "174D/V84R").split(?/).each do |s|
          s[0] = ?I if s[/\A174[D-R]\z/]
          s.replace "R100M" if "R100OM" == s
        end
      end
    end ) )
  end

  it :google2struct do
    unless File.exist? "temp.json"
      require "open-uri"
      File.write "temp.json", URI("https://storage.yandexcloud.net/gems.nakilon.pro/dsr/patent_imgf.json").open(&:read).tap{ |_| assert_equal "00b38499ce020c45657555759c508fb6", Digest::MD5.hexdigest(_) }
    end
    data = DSR.google2struct File.read "temp.json"
    assert_equal "a7552794c5ff5571849b428ea1babc12", Digest::MD5.hexdigest(data.to_json)
    check data
  end

end
