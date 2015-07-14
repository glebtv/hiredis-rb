require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

base = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

hiredis_dir = File.join(base, %w{vendor hiredis})

hiredis_makefile = File.join(base, %w{vendor hiredis Makefile})

unless File.file?(hiredis_makefile)
  STDERR.puts "vendor/hiredis missing, cloning..."
  Dir.chdir(base) do
    success = system("git submodule init")
    raise "Cloning hiredis failed" if !success
    success = system("git submodule update --recursive")
    raise "Cloning hiredis failed" if !success
  end
end

RbConfig::CONFIG['configure_args'] =~ /with-make-prog\=(\w+)/
make_program = $1 || ENV['make']
make_program ||= case RUBY_PLATFORM
when /mswin/
  'nmake'
when /(bsd|solaris)/
  'gmake'
else
  'make'
end

# Make sure hiredis is built...
Dir.chdir(hiredis_dir) do
  success = system("#{make_program} static")
  raise "Building hiredis failed" if !success
end

# Statically link to hiredis (mkmf can't do this for us)
$CFLAGS << " -I#{hiredis_dir}"
$LDFLAGS << " #{hiredis_dir}/libhiredis.a"

have_func("rb_thread_fd_select")
create_makefile('hiredis/ext/hiredis_ext')
