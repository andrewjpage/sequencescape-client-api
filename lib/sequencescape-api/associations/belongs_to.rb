require 'sequencescape-api/associations/base'

module Sequencescape::Api::Associations::BelongsTo
  class AssociationProxy < Sequencescape::Api::Associations::Base
    def initialize(*args, &block)
      super
      @object, @loaded = new(@attributes, false), false
    end

    def respond_to?(name, include_private = false)
      case
      when super                                      then true # One of our methods ...
      when @object.respond_to?(name, include_private) then true # ... eager loaded object method ...
      when !is_object_loaded? && is_attribute?(name)  then true # ... or an early attribute and no object ...
      else object.respond_to?(name, include_private)            # ... or force the object load and check
      end
    end

    def method_missing(name, *args, &block)
      return @attributes[name.to_s] if !is_object_loaded? and is_attribute?(name) and args.empty?
      object.send(name, *args, &block)
    end

    def is_attribute?(name)
      @attributes.key?(name.to_s)
    end
    private :is_attribute?

    def is_object_loaded?
      @loaded
    end
    private :is_object_loaded?

    def object
      @object   = nil unless @loaded
      @object ||= api.read(actions.read) do |json|
        new(json, true).tap { @loaded = true }
      end
      @object
    end
    private :object

    delegate :hash, :to => :@object
    def eql?(proxy_or_object)
      proxy_or_object = proxy_or_object.instance_variable_get(:@object) if proxy_or_object.is_a?(self.class)
      @object.eql?(proxy_or_object)
    end
  end

  def belongs_to(association, options = {}, &block)
    association = association.to_sym

    line = __LINE__ + 1
    class_eval(%Q{
      def #{association}(reload = false)
        associations[#{association.inspect}]   = nil if !!reload
        associations[#{association.inspect}] ||= AssociationProxy.new(self, #{association.inspect}, #{options.inspect})
        associations[#{association.inspect}]
      end

      def #{association}?
        attributes_for?(#{association.inspect})
      end
    }, __FILE__, line)
  end
end
