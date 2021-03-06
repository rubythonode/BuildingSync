require 'nokogiri'
require 'rubyXL'
require 'pp'

def add_spaces(str)
  retval = str.dup
  regex = /(.*?[^ (])([A-Z][a-z])(.*?)/
  while retval.match(regex)
    retval.gsub!(regex, '\1 \2\3')
  end
  regex = /(.*?)([a-z])([A-Z])(.*?)/
  while retval.match(regex)
    retval.gsub!(regex, '\1\2 \3\4')
  end
  # Custom fixes
  retval.gsub!('e GRID', 'eGRID')
  retval.gsub!('EC Ms', 'ECMs')
  retval
end

xsd = File.expand_path("#{File.dirname(__FILE__)}/../BuildingSync_2_0.xsd")
@schema = Nokogiri::XML(IO.read(xsd)) { |doc| doc.noblanks }
#@schema.remove_namespaces!
# puts @schema.css('element')
# puts @schema.xpath('//')

#elems = @schema.search 'element[name="Audits"]'
#puts elems.length
#elems.each_with_index { |elem, index|
#  puts elem if index == 0
#}

workbook = RubyXL::Workbook.new # Create workbook

#######################
# Project Data Fields #
#######################
project = workbook[0]
row = col = 0
project.sheet_name = 'Project Data Fields' # Sheet 1
project.merge_cells(row, col, row, 4) # Merges A1:F1
project.add_cell(row, col, 'BuildingSync Data Dictionary, ' + Time.now.strftime('%m/%d/%Y')) # Title
project[row][col].change_horizontal_alignment('center')
project.change_row_bold(row, true)
project.change_row_font_name(row, 'Calibri')
project.change_row_font_size(row, 24)
project.change_row_height(row, 42)
project.change_row_vertical_alignment(row, 'top')

# Headers
row += 1
headers = ['Category', 'Field', 'Description', 'Type', 'Units/Pattern']
widths = [15.14, 37.29, 67.86, 11, 17.86]
headers.map do |header|
  project.add_cell(row, col, header)
  project[row][col].change_horizontal_alignment('center')
  project.change_column_width(col, widths[col])
  col += 1
end
project.change_row_fill(row, '4f81bd')
project.change_row_font_color(row, 'ffffff')
project.change_row_bold(row, true)
project.change_row_font_name(row, 'Calibri')
project.change_row_font_size(row, 14)

categories = ['Site', 'Customer', 'Commercial Facilities', 'Block']


#######################
# Systems Data Fields #
#######################
systems = workbook.add_worksheet('Systems Data Fields') # Sheet 2

# Headers
row = col = 0
headers = ['Category', 'Field', 'Description', 'Type', 'Units/Pattern', 'Comment']
widths = [16.57, 38.71, 66.29, 14.57, 19.86, 11.29]
headers.map do |header|
  systems.add_cell(row, col, header)
  systems.sheet_data[row][col].change_horizontal_alignment('center')
  systems.change_column_width(col, widths[col])
  col += 1
end
systems.change_row_fill(row, '4f81bd')
systems.change_row_font_color(row, 'ffffff')
systems.change_row_bold(row, true)
systems.change_row_font_name(row, 'Calibri')
systems.change_row_font_size(row, 14)

########################
# Measures Data Fields #
########################
measures = workbook.add_worksheet('Measures Data Fields') # Sheet 3
children = @schema.xpath('/xs:schema/xs:complexType[@name="MeasureType"]/xs:sequence').children

# Headers
row = col = 0
headers = ['Category', 'Field', 'Description', 'Type', 'Units/Pattern']
widths = [16.14, 46.14, 63.29, 15.14, 19.43]
headers.map do |header|
  measures.add_cell(row, col, header)
  measures[row][col].change_horizontal_alignment('center')
  measures.change_column_width(col, widths[col])
  col += 1
end
measures.change_row_fill(row, '4f81bd')
measures.change_row_font_color(row, 'ffffff')
measures.change_row_bold(row, true)
measures.change_row_font_name(row, 'Calibri')
measures.change_row_font_size(row, 14)

#########################
# Reporting Data Fields #
#########################
reporting = workbook.add_worksheet('Reporting Data Fields') # Sheet 4

# Headers
row = col = 0
headers = ['Category', 'Field', 'Description', 'Type', 'Units/Pattern']
widths = [18.29, 29.57, 74.71, 13.43, 21.71]
headers.map do |header|
  reporting.add_cell(row, col, header)
  reporting.sheet_data[row][col].change_horizontal_alignment('center')
  reporting.change_column_width(col, widths[col])
  col += 1
end
reporting.change_row_fill(row, '4f81bd')
reporting.change_row_font_color(row, 'ffffff')
reporting.change_row_bold(row, true)
reporting.change_row_font_name(row, 'Calibri')
reporting.change_row_font_size(row, 14)

######################
# Final Enumerations #
######################
enumerations = workbook.add_worksheet('Final Enumerations') # Sheet 5

enums = {}
names = []
@schema.xpath('//xs:simpleType/xs:restriction').map { |node|
  name = node.parent.attribute('name')
  if name.nil?
    name = (name || node.parent.parent.attribute('name'))
  end
  name = name.value
  if name == 'ClimateZone' || name == 'LampLabel' || name == 'MeasureName' # Handle duplicate enum names
    sub_name = node.parent.parent.parent.parent.parent.attribute('name').value
    name += " (#{sub_name})"
  end
  if node.children.length
    names.push(name)
    dupes = names.detect{ |e| names.count(e) > 1 }
    raise 'Error: duplicate enum detected: ' + name if !dupes.nil?
    arr = []
    node.children.map { |child|
      value = child.attribute('value').value
      arr.push(value)
      dupes = arr.detect{ |e| arr.count(e) > 1 }
      raise "Error: duplicate enum value detected: '#{value}' in '#{name}'" if !dupes.nil?
    }
    enums[add_spaces(name)] = arr
  else
    # Empty enums
  end
}
col = 0
enums = enums.sort { |a, b| a[0].downcase <=> b[0].downcase }
enumerations.change_row_fill(0, '4f81bd')
enumerations.change_row_font_color(0, 'ffffff')
enumerations.change_row_bold(0, true)
enumerations.change_row_font_name(0, 'Calibri')
enumerations.change_row_font_size(0, 11)
max_row = 0
enums.map do |enum, values|
  row = 0
  enumerations.add_cell(row, col, enum)
  values.each do |value|
    row += 1
    enumerations.add_cell(row, col, value)
    if max_row < row
      enumerations.change_row_fill(row, 'dce6f1')
      enumerations.change_row_font_name(row, 'Calibri')
      enumerations.change_row_font_size(row, 11)
      max_row = row
    end
  end
  col += 1
end


# puts @schema.xpath('/xs:schema').children.length


font = RubyXL::Font.new
font.set_name('Calibri')
font.set_size(11)
workbook.save('BuildingSync Data Dictionary 2.0.xlsx') # Save

