import re
import sys

def clean_pbxproj(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    seen_file_refs = set()
    
    in_build_file_section = False
    
    for line in lines:
        if "/* Begin PBXBuildFile section */" in line:
            in_build_file_section = True
            new_lines.append(line)
            continue
        if "/* End PBXBuildFile section */" in line:
            in_build_file_section = False
            new_lines.append(line)
            continue
        
        if in_build_file_section:
            # Match: GUID /* comment */ = {isa = PBXBuildFile; fileRef = REF_GUID /* comment */; };
            match = re.search(r'(\w{24}) \/\* .* in Sources \*\/\s*=\s*\{isa = PBXBuildFile; fileRef = (\w{24})', line)
            if match:
                ref_guid = match.group(2)
                if ref_guid in seen_file_refs:
                    # Duplicate ref found, skip this build file definition
                    continue
                else:
                    seen_file_refs.add(ref_guid)
        
        new_lines.append(line)
    
    # Now we need to remove the GUIDs of the skipped files from the build phase lists.
    # But since we don't know which GUIDs we skipped in the loop above, 
    # let's calculate them first.
    
    # Re-scan to find GUIDs to remove
    all_build_files = []
    with open(file_path, 'r') as f:
        content = f.read()
        all_matches = re.findall(r'(\w{24}) \/\* .* in Sources \*\/\s*=\s*\{isa = PBXBuildFile; fileRef = (\w{24})', content)
        for guid, ref in all_matches:
            all_build_files.append((guid, ref))
    
    ref_to_first_guid = {}
    guids_to_remove = set()
    for guid, ref in all_build_files:
        if ref not in ref_to_first_guid:
            ref_to_first_guid[ref] = guid
        else:
            guids_to_remove.add(guid)
            
    # Now filter the lines again using the computed guids_to_remove
    final_lines = []
    for line in lines:
        # Remove definitions
        match = re.match(r'^\s*(\w{24}) \/\* .* in Sources \*\/\s*=', line)
        if match and match.group(1) in guids_to_remove:
            continue
        
        # Remove references in file lists
        for guid in guids_to_remove:
            if f"{guid} /*" in line:
                # Replace "GUID /* comment */," with ""
                line = re.sub(rf'{guid} \/\* .* \/\*,?', '', line)
        
        final_lines.append(line)
        
    with open(file_path, 'w') as f:
        f.write('\n'.join(final_lines))

if __name__ == "__main__":
    clean_pbxproj(sys.argv[1])
