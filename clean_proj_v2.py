import sys

def clean_pbxproj(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    seen_refs = set()
    
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
            # Check if line is a build file definition
            # Example: \tCF17D6DF30293C8800D9A476 /* TheBlackArchivesApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = C0DE1234567890ABCDEF01B /* TheBlackArchivesApp.swift */; };
            if "isa = PBXBuildFile" in line and "fileRef =" in line:
                # Extract the fileRef GUID
                parts = line.split("fileRef =")
                if len(parts) > 1:
                    ref_guid = parts[1].split()[0]
                    if ref_guid in seen_refs:
                        # Duplicate! Skip this line
                        continue
                    else:
                        seen_refs.add(ref_guid)
        
        new_lines.append(line)
    
    with open(file_path, 'w') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    clean_pbxproj(sys.argv[1])
