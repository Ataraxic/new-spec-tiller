require_relative 'spec_tiller/sync_test_suite'
require_relative 'spec_tiller/matrix_parser'
require 'pry'

spec_dir_glob = 'spec/**/*_spec.rb'
specs_in_dir = Dir.glob(spec_dir_glob).map { |file_path| file_path.slice(/(spec\/\S+$)/) }


filepath = 'spec/documents/.travis.yml'
travis_yaml = TravisYaml.new(filepath: filepath)

original_matrix = travis_yaml.build_matrix

# We ignore workers past num_builds count
matrix_post_ignored_lines = original_matrix.slice(0..travis_yaml.num_builds)
ignored_lines = original_matrix.slice(travis_yaml.num_builds..-1)

yaml_transforms = YamlTransforms.new
yaml_transforms.register_line_transform('TEST_SUITE') do |test_suite|
  test_suite.split(' ')
end
# remove ignored specs
yaml_transforms.register_line_transform('TEST_SUITE') do |test_suite|
  test_suite - travis_yaml.ignored_specs
end

default_travis_yaml = yaml_transforms.apply_transforms(matrix_post_ignored_lines)

# diff specs in yaml vs directory
yaml_spec_list = yaml_transforms.flatten_dedup(list: default_travis_yaml, key: 'TEST_SUITE')
specs_to_remove = yaml_spec_list - specs_in_dir
travis_after_remove = yaml_transforms.remove_specs(matrix: default_travis_yaml,
                                                   specs: specs_to_remove)

specs_to_add = specs_in_dir - yaml_spec_list

puts "  Removed: #{specs_to_remove}\n  Added:   #{specs_to_add}\n\n"

specs_by_index = yaml_transforms.rand_specs(specs: specs_to_add,
                                            num_builds: travis_after_remove.length)

travis_after_add = yaml_transforms.add_specs(matrix: travis_after_remove,
                                             specs_by_index: specs_by_index)

travis_after_empty_test_suite_removal = yaml_transforms.remove_empty_test_suite(travis_after_add)

travis_after_compacting = yaml_transforms.remove_empty_hash(travis_after_empty_test_suite_removal)

formatted_travis_matrix = yaml_transforms.format_matrix(matrix: travis_after_compacting)

travis_yaml.rewrite_matrix(formatted_travis_matrix)


