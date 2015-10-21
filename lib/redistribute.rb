require_relative 'travis_api'
require_relative 'spec_tiller/sync_test_suite'
require_relative 'spec_tiller/matrix_parser'

filepath = 'spec/documents/.travis.yml'
travis_yaml = TravisYaml.new(filepath: filepath)

num_builds = travis_yaml.num_builds
