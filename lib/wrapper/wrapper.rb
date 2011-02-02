module WresqueWrapper
  def self.extended(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  module ClassMethods
    def queue; @queue; end
    def queue=(queue); @queue = queue; end

    def default_queue; @default_queue; end
    def default_queue=(queue); @default_queue = queue; end

    def default_worker_queue(queue)
      @default_queue = queue
    end

    def perform(id, method, *args)
      ActiveRecord::Base.verify_active_connections!
      if id
        self.find(id).send(method, *args)
      else
        self.send(method, *args)
      end
    end

    def delay(opts={})
      WresqueWrapper::WrapperProxies::Proxy.new(self,self,nil,opts[:queue])
    end
  end

  module InstanceMethods
    def delay(opts={})
      WresqueWrapper::WrapperProxies::Proxy.new(self,self.class,self.id,opts[:queue])
    end
  end

  module WrapperProxies
    class Proxy
      attr_reader :target

      def initialize(target,klass,target_id,queue)
        queue ||= klass.default_queue
        unless queue
          raise RuntimeError, "No queue specified, and target class has no default queue", caller
        end
        @target = target
        @klass = klass
        @target_id = target_id
        @klass.queue = queue
      end

      def method_missing(method,*args)
        if @target.respond_to?(method)
          Resque.enqueue(@klass,@target_id,method,*args)
        else
          @target.send(method,*args)
        end
      end

      def respond_to?(method)
        super || @target.respond_to?(method)
      end
    end
  end
end
