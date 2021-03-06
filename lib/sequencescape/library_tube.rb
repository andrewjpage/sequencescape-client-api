require 'sequencescape-api/resource'

class Sequencescape::LibraryTube < ::Sequencescape::Api::Resource
  has_many   :requests
  belongs_to :sample
  belongs_to :source_request, :class_name => 'Sequencescape::Request'
end
