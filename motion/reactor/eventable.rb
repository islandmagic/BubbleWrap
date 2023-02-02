module BubbleWrap
  module Reactor
    # A simple mixin that adds events to your object.
    module Eventable
      # When `event` is triggered the block will execute
      # and be passed the arguments that are passed to
      # `trigger`.
      def on(event, method = nil, &blk)
        __events_semaphore.wait
        events = _events_for_key(event)
        method_or_block = method ? method : blk
        events.push method_or_block
        __events_semaphore.signal
      end

      # When `event` is triggered, do not call the given
      # block any more
      def off(event, method = nil, &blk)
        __events_semaphore.wait
        events = _events_for_key(event)
        if method
          events.delete_if { |m| m.receiver == method.receiver and m.name == method.name }
        elsif blk
          events.delete_if { |b| b == blk }
        else
          __events__.delete(event)
        end
        __events_semaphore.signal
        blk
      end

      # Trigger an event
      def trigger(event, *args)
        __events_semaphore.wait
        begin
          blks = _events_for_key(event).clone
        rescue => e
          blks = []
        end
        __events_semaphore.signal
        blks.map do |blk|
          if blk
            Dispatch::Queue.concurrent(:default).async do 
              blk.call(*args) if blk
            end
          end
        end
      end

      private
 
      def __events__
        @__events__ ||= Hash.new
      end
         
      def _events_for_key(event)
        if !__events__.has_key?(event) || __events__[event].nil?
          __events__[event] = Array.new
        end
        __events__[event]
      end

      def __events_semaphore
        @__events_semaphore ||= Dispatch::Semaphore.new(1)
      end
    end
  end
end
