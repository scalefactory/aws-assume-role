require 'coveralls'
Coveralls.wear_merged!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])

SimpleCov.start do

  project_name 'AWS Assume Role'

  add_filter '/spec/'
  add_filter 'lib/aws_assume_role/vendored'

  %w(aws_assume_role).each do |group_name|
    add_group(group_name, "/#{group_name}/lib")
  end

  merge_timeout 60 * 15 # 15 minutes

end
