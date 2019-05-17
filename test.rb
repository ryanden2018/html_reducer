#!/usr/bin/env ruby

require_relative 'html_reducer.rb'

str = open('test.html').read.gsub("\r","").gsub("\n","");

result = html_reducer(str);


def print_results(contents,nesting_depth=0)
  tab = "    "
  contents.each do |elem|
    if elem.class == HTML_element
      puts tab*nesting_depth + elem.to_s
      print_results(elem.contents,nesting_depth+1)
      if !elem.to_s.end_with?("/>")
        puts tab*nesting_depth + "</#{elem.tag}>"
      end
    else 
      puts tab*nesting_depth + elem.to_s
    end
  end
end

print_results(result)
