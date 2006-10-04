module Spec
  module Mocks
    module MockInstanceMethods
      # Creates a new mock with a +name+ (that will be used in error messages only)
      # Options:
      # * <tt>:null_object</tt> - if true, the mock object acts as a forgiving null object allowing any message to be sent to it.
      def initialize(name, options={})
        @name = name
        @options = DEFAULT_OPTIONS.dup.merge(options)
        @expectations = []
        @expectation_ordering = OrderGroup.new
      end

      def should_receive(sym, &block)
        add MessageExpectation, caller(1)[0], sym, &block
      end

      def should_not_receive(sym, &block)
        add NegativeMessageExpectation, caller(1)[0], sym, &block
      end

      def __verify #:nodoc:
        @expectations.each do |expectation|
          expectation.verify_messages_received
        end
      end

      def __clear_expectations #:nodoc:
        @expectations.clear
      end

      def method_missing(sym, *args, &block)
        begin
          return self if @options[:null_object]
          super(sym, *args, &block)
        rescue NoMethodError
          arg_message = args.collect{|arg| "<#{arg}:#{arg.class.name}>"}.join(", ")
          Kernel::raise Spec::Mocks::MockExpectationError, "Mock '#{@name}' received unexpected message '#{sym}' with [#{arg_message}]"
        end
      end

    private

      DEFAULT_OPTIONS = {
        :null_object => false
      }

      def add(expectation_class, expected_from, sym, &block)
        define_expected_method(sym)
        expectation = expectation_class.send(:new, @name, @expectation_ordering, expected_from, sym, block_given? ? block : nil)
        @expectations << expectation
        expectation
      end

      def metaclass
        class << self; self; end
      end

      def define_expected_method(sym)
        metaclass.__send__ :class_eval, %{
          def #{sym}(*args, &block)
            message_received :#{sym}, *args, &block # ?
          end
        }
      end

      def message_received(sym, *args, &block)
        if expectation = find_matching_expectation(sym, *args)
          expectation.invoke(args, block)
        else
          method_missing(sym, *args, &block)
        end
      end

      def find_matching_expectation(sym, *args)
        expectation = @expectations.find {|expectation| expectation.matches(sym, args)}
      end
    end

    class Mock
      include MockInstanceMethods
    end
  end
end