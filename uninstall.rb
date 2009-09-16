require 'fileutils'
require 'assets'

ASSETS.each_pair do |dir, files|
  files.each do |file|
    FileUtils.rm(File.join(Rails.root, 'public', dir, file), :verbose => true)
  end
end

puts
puts '========== UnInstallation of "uni-form" is completed ========'
puts

