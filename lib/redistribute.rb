require_relative 'travis_api'
require_relative 'spec_tiller/sync_test_suite'
require_relative 'spec_tiller/matrix_parser'

filepath = 'spec/documents/.travis.yml'
travis_yaml = TravisYaml.new(filepath: filepath)

num_builds = travis_yaml.num_builds

spec_dir_glob = 'spec/**/*_spec.rb'
specs_in_dir = Dir.glob(spec_dir_glob).map { |file_path| file_path.slice(/(spec\/\S+$)/) }

