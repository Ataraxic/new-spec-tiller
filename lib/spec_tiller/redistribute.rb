relative_require 'travis_api'

class Redistribute
  def initialize(yaml)
    @yaml = yaml
  end

  def write_yaml
    @yaml.rewrite_matrix()
  end

  def distribute(seed:, profiles:)
    
  end
end

class SpecParser

  def initialize(build_log)
    @spec_list = parse_profile_results(@build_log)
  end

  private

  PROFILE_REGEX = /\s{1}\(([0-9\.]*\s).*\.\/(spec.*):/

  def parse_profile_results(build_log)
    specs = build_log.scan(PROFILE_REGEX).uniq { |spec| spec.last }
    specs.map do |spec|
      {
       :duration => spec.first,
       :filepath => spec.last
      }
    end.sort_by(&:test_duration)
  end
end
