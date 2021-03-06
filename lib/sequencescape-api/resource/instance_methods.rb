require 'ostruct'

module Sequencescape::Api::Resource::InstanceMethods
  def self.included(base)
    base.class_eval do
      attr_reader :api, :actions, :attributes
      private :api, :actions, :attributes
      delegate_to_attributes :uuid
      alias_method(:model, :class)

      delegate :hash, :to => :uuid

      time_attribute :created_at, :updated_at
    end
  end

  def eql?(object_or_proxy)
    return false unless object_or_proxy.respond_to?(:uuid)
    self.uuid.eql?(object_or_proxy.uuid)
  end

  def initialize(api, json = nil, wrapped = false)
    @api = api
    update_from_json(json, wrapped)
  end

  def update_attributes!(attributes)
    self.tap do
      api.update(actions.update, { json_root => attributes }) do |json|
        update_from_json(json, true)
      end
    end
  end

  def respond_to?(name, include_private = false)
    super || attributes.key?(name.to_s)
  end

  def method_missing(name, *args, &block)
    return yield if name.to_s =~ /^_run_.+_callbacks$/
    (args.empty? and attributes.key?(name.to_s)) ? attributes[name.to_s] : super
  end
  protected :method_missing

  def as_json(options = nil)
    uuid
  end
  protected :as_json

  def update_from_json(json, wrapped = false)
    @attributes = (wrapped ? unwrapped_json(json) : json) || {}
    @actions    = OpenStruct.new(@attributes.delete('actions'))
  end
  private :update_from_json

  def unwrapped_json(json)
    json[(json.keys - [ 'uuids_to_ids' ]).first]
  end
  private :unwrapped_json
end
