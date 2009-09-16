require 'fileutils'

ASSETS = {
  'stylesheets' => %w{uni-form.css uni-form-generic.css},
  'javascripts' => %w{uni-form.prototype.js jquery.uni-form.js}
}

ASSETS.each_pair do |dir, files|
  files.each do |file|
    FileUtils.cp(File.join(File.dirname(__FILE__), 'resources', 'public', dir, file),
                 File.join(Rails.root, 'public', dir), :verbose => true)
  end
end

puts
puts '========== Installation of "uni-form" is completed =========='
puts
puts IO.read(File.join(File.dirname(__FILE__), 'README'))
