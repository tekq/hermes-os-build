import subprocess
import json
import sys

PACKAGES = ["zstd", "xz", "openssl", "lz4"]
MY_REPO_URL = "https://tekq.github.io/fhp-build/x86_64/"
FEDORA_RELEASE = "43"

def get_version(repo_id, package, url=None):
    """Queries dnf for the latest version of a package in a specific repo."""
    cmd = [
        "dnf", "repoquery", 
        "--latest-limit=1", 
        "--qf", "%{VERSION}-%{RELEASE}",
        package
    ]
    
    if url:
        cmd.extend(["--repofrompath", f"{repo_id},{url}", "--repo", repo_id])
    else:
        cmd.extend(["--repo", "updates", "--repo", "fedora"])

    try:
        result = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
        return result if result else "0"
    except:
        return "0"

def main():
    rebuild_list = []
    
    print(f"{'Package':<15} | {'Fedora':<20} | {'Current':<20}")
    print("-" * 60)
    
    for pkg in PACKAGES:
        fedora_v = get_version("fedora", pkg)
        my_v = get_version("fhp-build", pkg, MY_REPO_URL)
        
        status = "OK"
        if fedora_v > my_v:
            status = "REBUILD"
            rebuild_list.append(pkg)
            
        print(f"{pkg:<15} | {fedora_v:<20} | {my_v:<20} | {status}")

    if rebuild_list:
        print(f"Triggering build for: {json.dumps(rebuild_list)}")
    else:
        print("\nAll packages up to date.")

if __name__ == "__main__":
    main()
