require_relative 'spec_tiller/sync_test_suite'
require_relative 'spec_tiller/matrix_parser'
require 'pry'


filepath = 'spec/documents/.travis.yml'
spec_dir_glob = 'spec/**/*_spec.rb'

travis_yaml = TravisYaml.new(filepath: filepath, spec_dir: spec_dir_glob)

original_matrix = TravisYaml.build_matrix

# We ignore workers past num_builds count
matrix_post_ignored_lines = original_matrix.slice(0..TravsYaml.num_builds)
ignored_lines = matrix.slice(TravisYaml.num_builds..-1)

yaml_tranforms = YamlTransforms.new

yaml_transforms.register_line_transform('TEST_SUITE') do |test_suite|
  TravisYaml.ignored_specs.each do |spec|
    test_suite.gsub!(spec, '')
  end
  test_suite
end

yaml_transforms.register_line_transform('TEST_SUITE') do |test_suite|
  test_suite.split(' ')
end

default_travis_yaml = yaml_transforms.apply_transforms(matrix_post_ignored_lines)

binding.pry



def generate_filepaths(line)
  spec_list = line['TEST_SUITE'].split(' ')
end

def specs_in_dir
  SyncTestSuite.get_current_file_list('spec/**/*_spec.rb')
end

def remove_ignored_specs(spec_line, specs_to_ignore)
  specs_to_ignore.each do |spec|
    spec_line = spec_line.gsub(spec, '')
  end
  spec_line
end

filepath = 'spec/documents/.travis.yml'
ignored_specs = SyncTestSuite.get_ignored_specs(filepath)

env_var_transforms = [
                      lambda do |line|
                        return line unless line['TEST_SUITE']
                        line['TEST_SUITE'] = remove_ignored_specs(line['TEST_SUITE'],ignored_specs)
                        line['TEST_SUITE'] = line['TEST_SUITE'].split(' ')
                        line
                      end
                     ]


# gets [env][matrix]
matrix = SyncTestSuite.get_build_matrix(filepath)

# removes lines past num_builds count
matrix_post_removed_lines = matrix.slice(0..SyncTestSuite.num_builds(filepath))
removed_lines = matrix.slice(SyncTestSuite.num_builds(filepath)..-1)

# applies any data transformations to variables
current_travis_matrix = matrix_post_removed_lines.map do |line|
  env_var_transforms.reduce(line) do |accum, curr|
    curr.call(accum)
  end
end

# gets flat list of all specs
specs_in_travis_yaml = current_travis_matrix.reduce([]) do |accum, curr|
  spec_list = curr['TEST_SUITE'] ? curr['TEST_SUITE'] : []
  accum + spec_list
end

# remove specs in travis yaml
specs_to_remove = specs_in_travis_yaml - specs_in_dir
travis_yaml_post_ignored = current_travis_matrix.map do |line|
  next line if line['TEST_SUITE'].nil?
  new_line = line.clone
  new_line['TEST_SUITE'] = line['TEST_SUITE'].clone - specs_to_remove
  new_line
end

specs_to_add = specs_in_dir - specs_in_travis_yaml
new_spec_list = specs_in_travis_yaml - specs_to_remove + specs_to_add

leftover_specs = new_spec_list.clone
current_travis_matrix.each do |line|
  next if line['TEST_SUITE'].nil?
  leftover_specs = leftover_specs - line['TEST_SUITE'] if line['TEST_SUITE']
end

num_builds = SyncTestSuite.num_builds(filepath)
specs_to_add_by_index = {}
leftover_specs.each do |spec|
  index = rand(leftover_specs.length)
  if specs_to_add_by_index[index]
    specs_to_add_by_index[index] += [spec]
  else
    specs_to_add_by_index[index] = [spec]
  end
end

puts leftover_specs
new_travis_matrix = travis_yaml_post_ignored.each_with_index.map do |line,i|
  next line if line['TEST_SUITE'].nil? || specs_to_add_by_index[i].nil?
  new_line = line.clone
  new_line['TEST_SUITE'] = line['TEST_SUITE'].clone + specs_to_add_by_index[i]
  new_line
end


binding.pry
# diff = travis_spec_list - generate_current_spec




