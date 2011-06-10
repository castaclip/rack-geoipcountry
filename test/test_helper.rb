begin
  # Require the preresolved locked set of gems.
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require 'rubygems'
  require 'bundler'
  Bundler.setup
end

require 'simplecov'
SimpleCov.start

Bundler.require(:default, :test)
<<<<<<< HEAD
require 'riot/rr'
=======
require 'riot/rr'
>>>>>>> fef4da1ae9f749aec00e5280716a724a14a75295
