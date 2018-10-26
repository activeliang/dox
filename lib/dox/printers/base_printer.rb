module Dox
  module Printers
    class BasePrinter
      def initialize(output)
        @output = output
      end

      def print
        raise NotImplementedError
      end

      private

      def descriptions_folder_path
        Dox.config.desc_folder_path
      end

      def print_desc(desc, fullpath = false)
        return if desc.blank?

        if desc.to_s =~ /.*\.md$/
          path = if fullpath
                   desc
                 else
                   descriptions_folder_path.join(desc).to_s
                 end
          content(path)
        else
          desc
        end
      end

      def content(path)
        File.read(path)
      end

      def indent_lines(number_of_spaces, string)
        string
          .split("\n")
          .map { |a| a.prepend(' ' * number_of_spaces) }
          .join("\n")
      end
    end
  end
end
