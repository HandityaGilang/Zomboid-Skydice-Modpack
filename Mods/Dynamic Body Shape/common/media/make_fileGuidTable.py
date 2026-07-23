import os
import uuid
from xml.etree import ElementTree as ET

# Define the directories
clothing_dir = './clothing/clothingItems'
table_file = 'fileGuidTable.xml'

# Find all .xml files in the clothingItems directory
xml_files = [f for f in os.listdir(clothing_dir) if f.endswith('.xml')]

# Parse the fileGuidTable.xml
table_tree = ET.parse(table_file)
table_root = table_tree.getroot()

# Iterate over the xml files
for xml_file in xml_files:
    # Generate a new GUID
    new_guid = str(uuid.uuid4())

    # Parse the xml file
    file_tree = ET.parse(os.path.join(clothing_dir, xml_file))
    file_root = file_tree.getroot()

    # Change the GUID value
    for guid in file_root.iter('m_GUID'):
        guid.text = new_guid

    # Save the changes
    file_tree.write(os.path.join(clothing_dir, xml_file))

    # Add the file location and GUID to the fileGuidTable.xml
    new_file = ET.SubElement(table_root, 'files')
    path = ET.SubElement(new_file, 'path')
    path.text = os.path.join('media/clothing/clothingItems', xml_file)
    guid = ET.SubElement(new_file, 'guid')
    guid.text = new_guid

# Save the changes to the fileGuidTable.xml
table_tree.write(table_file)