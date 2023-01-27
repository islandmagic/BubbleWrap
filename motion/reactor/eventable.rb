module BubbleWrap
  module Reactor
    # A simple mixin that adds events to your object.
    module Eventable

      # When `event` is triggered the block will execute
      # and be passed the arguments that are passed to
      # `trigger`.
      def on(event, method = nil, &blk)
        events = _events_for_key(event)
        method_or_block = method ? method : blk
        events.push method_or_block
      end

      # When `event` is triggered, do not call the given
      # block any more
      def off(event, method = nil, &blk)
        events = _events_for_key(event)
        if method
          events.delete_if { |m| m.receiver == method.receiver and m.name == method.name }
        elsif blk
          events.delete_if { |b| b == blk }
        else
          __events__[event] = nil
        end
        blk
      end

      # Trigger an event
      def trigger(event, *args)
        blks = _events_for_key(event).clone
        blks.map do |blk|
          blk.call(*args)
        end
      end

      private
 
      def __events__
        if @__events__.nil?
          @__events__ = Hash.new
        end
        @__events__
      end
         
      def _events_for_key(event)
        if __events__[event].nil?
          __events__[event] = Array.new
        end
        __events__[event]
      end
    end
  end
end
