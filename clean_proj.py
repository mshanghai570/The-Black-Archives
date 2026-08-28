import re
import sys

def clean_pbxproj(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. Identify the PBXBuildFile section
    start_marker = "/* Begin PBXBuildFile section */"
    end_marker = "/* End PBXBuildFile section */"
    
    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)
    
    if start_idx == -1 or end_idx == -1:
        print("Could not find PBXBuildFile section")
        return

    section = content[start_idx:end_idx]
    
    # Find all entries: GUID /* comment */ = {isa = PBXBuildFile; fileRef = FILE_GUID /* comment */; };
    # We use a regex that captures the build file GUID and the file reference GUID
    pattern = re.compile(r'(\w{24}) \/\* .* in Sources \*\/\s*=\s*\{isa = PBXBuildFile; fileRef = (\w{24})')
    matches = pattern.findall(section)
    
    ref_to_guid = {}
    guids_to_remove = set()
    
    for guid, ref in matches:
        if ref not in ref_to_guid:
            ref_to_guid[ref] = guid
        else:
            guids_to_remove.add(guid)
            
    print(f"Found {len(matches)} build file entries. Removing {len(guids_to_remove)} duplicates.")
    
    # Now we need to remove these GUIDs from the file.
    # We will do this by replacing the full definition line of the duplicate GUIDs.
    
    lines = content.splitlines()
    final_lines = []
    
    for line in lines:
        # Match a line that defines one of the duplicate GUIDs
        # Pattern: \tGUID /* comment */ = {isa = PBXBuildFile...
        match = re.match(r'^\s*(\w{24}) \/\* .* in Sources \*\/\s*=', line)
        if match:
            guid = match.group(1)
            if guid in guids_to_remove:
                continue # Skip this line
        final_lines.append(line)
    
    content = '\n'.join(final_lines)
    
    # 2. Now remove the duplicate GUIDs from the build phase file lists
    # Search for the GUIDs in the file lists and remove them.
    for guid in guids_to_remove:
        # Match the GUID followed by the comment and a comma or newline
        # Example: CF17D6E030293C8800D9A476 /* TheBlackArchivesApp.swift in Sources */,
        pattern = re.compile(rf'{guid} \/\* .* in Sources \*\/\s*,?')
        content = pattern.sub('', content)
        
    # Clean up trailing commas in lists: ", );" -> ");"
    content = content.replace(', );', ');')
    content = content.replace(', \n\t\t)', '\n\t\t)')
    
    with open(file_path, 'w') as f:
        f.write(content)
    print("Successfully cleaned pbxproj.")

if __name__ == "__main__":
    clean_pbxproj(sys.argv[1])
