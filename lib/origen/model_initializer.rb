module Origen
  module ModelInitializer
    extend ActiveSupport::Concern

    module ClassMethods
      # This overrides the new method of any class which includes this
      # module to force the newly created instance to be registered as
      # a top-level listener.
      def new(*args, &block) # :nodoc:
        options = args.find { |a| a.is_a?(Hash) } || {}

        x = allocate
        x.send(:init_top_level) if x.respond_to?(:includes_origen_top_level?)
        x.send(:init_sub_blocks, *args) if x.respond_to?(:init_sub_blocks)
        
        if x.respond_to?(:version=)
          version = options[:version]
          version ||= args.first if args.first.is_a?(Fixnum)
          x.version = version
        end
        if x.respond_to?(:parent=)
          parent = options.delete(:parent)
          x.parent = parent if parent
        end
        
        # Maybe make this a callback?
        #x.send(:init_componentables) if x.respond_to?(:init_componentables)
        #Origen::Componentable.model_init(x)
        #puts x
        x.class.included_modules.each do |mod|
          #puts "#{x.class}: #{mod}: #{mod.class}"
          #Origen::ModelInitializer.boot_module(mod, x)
          
          mod.send(:origen_model_init, x) if mod.respond_to?(:origen_model_init)
          mod.constants.each do |constant|
            #puts "#{constant}: #{constant.class}: #{mod}"
            if mod.const_defined?(constant)
              mod.const_get(constant).send(:origen_model_init, x) if mod.const_get(constant).respond_to?(:origen_model_init)
            end
          end
          #puts "HAS: #{mod}" if mod.respond_to?(:origen_model_init)
        end
        
        options.each do |k, v|
          x.send(:instance_variable_set, "@#{k}", v) if x.respond_to?(k)
        end
        if x.respond_to?(:pre_initialize)
          if x.method(:pre_initialize).arity == 0
            x.send(:pre_initialize, &block)
          else
            x.send(:pre_initialize, *args, &block)
          end
        end
        if x.method(:initialize).arity == 0
          x.send(:initialize, &block)
        else
          x.send(:initialize, *args, &block)
        end
        x.send(:_initialized) if x.respond_to?(:is_an_origen_model?)
        if x.respond_to?(:register_callback_listener)
          Origen.after_app_loaded do |app|
            x.register_callback_listener
          end
        end
        # Do this before wrapping, otherwise the respond to method in the controller will
        # be looking for the model to be instantiated when it is not fully done yet
        is_top_level = x.respond_to?(:includes_origen_top_level?)
        if x.respond_to?(:wrap_in_controller)
          x = x.wrap_in_controller
        end
        if is_top_level
          Origen.app.listeners_for(:on_top_level_instantiated, top_level: false).each do |listener|
            listener.on_top_level_instantiated(x)
          end
        end
        x
      end
    end
  end
end
