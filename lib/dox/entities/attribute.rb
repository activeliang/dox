module Dox
  module Entities
    class Attribute
      def initialize(name, options)
        @name = name
        @default = options[:default]
        @type = options[:type]
        @desc = options[:desc] || options[:desc]
        @additional_desc = options[:additional_desc]
        @example_value = options[:example]
        @required = options[:required] || false
        @members = options[:members]
        @children = options[:children]
      end

      def print
        children? ? print_object : print_rest
      end

      def print_rest
        [
          main,
          ("    #{@additional_desc}" if @additional_desc),
          ("    Default: #{default_value}" if @default),
          ('    + Members ' if @members),
          members
        ].compact.join("\n")
      end

      def print_object
        [
          "+ #{@name}",
          '(',
          @required ? 'required' : 'optional',
          ')'
        ].compact.join(' ')
      end

      def main
        [
          "+ #{@name}:",
          ("`#{@example}`" if @example),
          '(',
          printed_type,
          @required ? ', required' : ', optional',
          ')',
          ("- #{@desc}" if @desc)
        ].compact.join(' ')
      end

      def printed_type
        return type unless @members
        "enum[#{type}]"
      end

      def type
        case @type
        when :integer, :double, :float then :number
        when :hash then :object
        else @type
        end
      end

      def children?
        @children.present?
      end

      def default_value
        return @default unless @default.respond_to?(:call)
        @default.call
      end

      def members
        return unless @members
        @members.map do |name, options|
          [
            '        +',
            "`#{name}`",
            ("- #{options[:desc]}" if options[:desc])
          ].join(' ')
        end
      end

      def children
        @children
      end
    end
  end
end