#!/usr/bin/env python3
"""Generate a minimal but valid Xcode project (.xcodeproj) for CoolBar."""

import hashlib
import os
import uuid

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
XCODEPROJ_DIR = os.path.join(PROJECT_DIR, "CoolBar.xcodeproj")
os.makedirs(XCODEPROJ_DIR, exist_ok=True)

SOURCES_DIR = os.path.join(PROJECT_DIR, "Sources")
RESOURCES_DIR = os.path.join(PROJECT_DIR, "Resources")

def gen_id(seed):
    """Generate a 24-char hex ID from a seed string."""
    h = hashlib.md5(seed.encode()).hexdigest()[:24].upper()
    # Ensure starts with a letter (PBX requirement)
    return h

# Collect all source files
source_files = []
for root, dirs, files in os.walk(SOURCES_DIR):
    for f in files:
        if f.endswith(".swift"):
            rel = os.path.relpath(os.path.join(root, f), PROJECT_DIR)
            source_files.append(rel)

# Resource files
resource_files = []
for root, dirs, files in os.walk(RESOURCES_DIR):
    for f in files:
        if f != ".DS_Store":
            rel = os.path.relpath(os.path.join(root, f), PROJECT_DIR)
            resource_files.append(rel)

print(f"Found {len(source_files)} source files, {len(resource_files)} resource files")

# --- Generate UUIDs ---
ids = {}

def uid(key):
    if key not in ids:
        ids[key] = gen_id(key)
    return ids[key]

# Project
PROJ_ID = uid("PBXProject")
MAIN_GROUP_ID = uid("mainGroup")
SOURCES_GROUP_ID = uid("sourcesGroup")
RESOURCES_GROUP_ID = uid("resourcesGroup")
PRODUCTS_GROUP_ID = uid("productsGroup")
TARGET_ID = uid("nativeTarget")
PRODUCT_REF_ID = uid("productRef")
BUILD_CONFIG_LIST_PROJ = uid("buildConfigList_project")
BUILD_CONFIG_LIST_TARGET = uid("buildConfigList_target")
BUILD_CONFIG_DEBUG_PROJ = uid("debugConfig_project")
BUILD_CONFIG_RELEASE_PROJ = uid("releaseConfig_project")
BUILD_CONFIG_DEBUG_TARGET = uid("debugConfig_target")
BUILD_CONFIG_RELEASE_TARGET = uid("releaseConfig_target")
SOURCES_BUILD_PHASE_ID = uid("sourcesBuildPhase")
RESOURCES_BUILD_PHASE_ID = uid("resourcesBuildPhase")
FRAMEWORKS_BUILD_PHASE_ID = uid("frameworksBuildPhase")

# File refs and build files
file_refs = {}
build_files = {}
subgroups = {}

for f in source_files:
    fid = uid(f"fileRef_{f}")
    bid = uid(f"buildFile_{f}")
    file_refs[f] = fid
    build_files[f] = bid

for f in resource_files:
    fid = uid(f"fileRef_{f}")
    bid = uid(f"buildFile_{f}")
    file_refs[f] = fid
    build_files[f] = bid

# --- Build sub-groups from directory structure ---
dirs_seen = set()
for f in source_files:
    parts = f.split("/")
    if parts[0] == "Sources" and len(parts) > 2:
        d = "Sources/" + parts[1]
        if d not in dirs_seen:
            dirs_seen.add(d)
            subgroups[d] = uid(f"group_{d}")

# --- Generate pbxproj ---
lines = []
def w(s=""):
    lines.append(s)

w("// !$*UTF8*$!")
w("{")

# Archive version
w(f"\tarchiveVersion = 1;")
w(f"\tclasses = {{}};")
w(f"\tobjectVersion = 56;")

# Objects
w(f"\tobjects = {{")
w()

# --- PBXBuildFile ---
for f in source_files:
    bid = build_files[f]
    fid = file_refs[f]
    w(f"\t\t{bid} /* {os.path.basename(f)} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {os.path.basename(f)} */; }};")

for f in resource_files:
    bid = build_files[f]
    fid = file_refs[f]
    w(f"\t\t{bid} /* {os.path.basename(f)} in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {os.path.basename(f)} */; }};")

w()

# --- PBXFileReference ---
for f in source_files:
    fid = file_refs[f]
    w(f"\t\t{fid} /* {os.path.basename(f)} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{os.path.basename(f)}\"; sourceTree = \"<group>\"; }};")

for f in resource_files:
    fid = file_refs[f]
    ext = os.path.splitext(f)[1]
    if ext == ".plist":
        ft = "text.plist.xml"
    else:
        ft = "file"
    w(f"\t\t{fid} /* {os.path.basename(f)} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; path = \"{os.path.basename(f)}\"; sourceTree = \"<group>\"; }};")

# Product ref
w(f"\t\t{PRODUCT_REF_ID} /* CoolBar.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = CoolBar.app; sourceTree = BUILT_PRODUCTS_DIR; }};")

w()

# --- PBXGroup (Sources subgroups) ---
for d, gid in subgroups.items():
    subdir = d.split("/")[1]
    w(f"\t\t{gid} /* {subdir} */ = {{")
    w(f"\t\t\tisa = PBXGroup;")
    w(f"\t\t\tchildren = (")
    for f in source_files:
        if f.startswith(d + "/"):
            w(f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */,")
    w(f"\t\t\t);")
    w(f"\t\t\tpath = {subdir};")
    w(f"\t\t\tsourceTree = \"<group>\";")
    w(f"\t\t}};")
    w()

# --- PBXGroup (Sources root) ---
w(f"\t\t{SOURCES_GROUP_ID} /* Sources */ = {{")
w(f"\t\t\tisa = PBXGroup;")
w(f"\t\t\tchildren = (")
# Files directly in Sources/
for f in source_files:
    parts = f.split("/")
    if len(parts) == 2:  # Sources/filename.swift
        w(f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */,")
# Subgroups
for d, gid in subgroups.items():
    w(f"\t\t\t\t{gid} /* {d.split('/')[1]} */,")
w(f"\t\t\t);")
w(f"\t\t\tpath = Sources;")
w(f"\t\t\tsourceTree = \"<group>\";")
w(f"\t\t}};")
w()

# --- PBXGroup (Resources) ---
w(f"\t\t{RESOURCES_GROUP_ID} /* Resources */ = {{")
w(f"\t\t\tisa = PBXGroup;")
w(f"\t\t\tchildren = (")
for f in resource_files:
    w(f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */,")
w(f"\t\t\t);")
w(f"\t\t\tpath = Resources;")
w(f"\t\t\tsourceTree = \"<group>\";")
w(f"\t\t}};")
w()

# --- PBXGroup (Products) ---
w(f"\t\t{PRODUCTS_GROUP_ID} /* Products */ = {{")
w(f"\t\t\tisa = PBXGroup;")
w(f"\t\t\tchildren = (")
w(f"\t\t\t\t{PRODUCT_REF_ID} /* CoolBar.app */,")
w(f"\t\t\t);")
w(f"\t\t\tname = Products;")
w(f"\t\t\tsourceTree = \"<group>\";")
w(f"\t\t}};")
w()

# --- Main Group ---
w(f"\t\t{MAIN_GROUP_ID} = {{")
w(f"\t\t\tisa = PBXGroup;")
w(f"\t\t\tchildren = (")
w(f"\t\t\t\t{SOURCES_GROUP_ID} /* Sources */,")
w(f"\t\t\t\t{RESOURCES_GROUP_ID} /* Resources */,")
w(f"\t\t\t\t{PRODUCTS_GROUP_ID} /* Products */,")
w(f"\t\t\t);")
w(f"\t\t\tsourceTree = \"<group>\";")
w(f"\t\t}};")
w()

# --- PBXNativeTarget ---
w(f"\t\t{TARGET_ID} /* CoolBar */ = {{")
w(f"\t\t\tisa = PBXNativeTarget;")
w(f"\t\t\tbuildConfigurationList = {BUILD_CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget \"CoolBar\" */;")
w(f"\t\t\tbuildPhases = (")
w(f"\t\t\t\t{SOURCES_BUILD_PHASE_ID} /* Sources */,")
w(f"\t\t\t\t{FRAMEWORKS_BUILD_PHASE_ID} /* Frameworks */,")
w(f"\t\t\t\t{RESOURCES_BUILD_PHASE_ID} /* Resources */,")
w(f"\t\t\t);")
w(f"\t\t\tbuildRules = (")
w(f"\t\t\t);")
w(f"\t\t\tdependencies = (")
w(f"\t\t\t);")
w(f"\t\t\tname = CoolBar;")
w(f"\t\t\tproductName = CoolBar;")
w(f"\t\t\tproductReference = {PRODUCT_REF_ID} /* CoolBar.app */;")
w(f"\t\t\tproductType = \"com.apple.product-type.application\";")
w(f"\t\t}};")
w()

# --- PBXProject ---
w(f"\t\t{PROJ_ID} /* Project object */ = {{")
w(f"\t\t\tisa = PBXProject;")
w(f"\t\t\tattributes = {{")
w(f"\t\t\t\tBuildIndependentTargetsInParallel = 1;")
w(f"\t\t\t\tLastSwiftUpdateCheck = 1630;")
w(f"\t\t\t\tLastUpgradeCheck = 1630;")
w(f"\t\t\t}};")
w(f"\t\t\tbuildConfigurationList = {BUILD_CONFIG_LIST_PROJ} /* Build configuration list for PBXProject \"CoolBar\" */;")
w(f"\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
w(f"\t\t\tdevelopmentRegion = \"zh-Hans\";")
w(f"\t\t\thasScannedForEncodings = 0;")
w(f"\t\t\tknownRegions = (")
w(f"\t\t\t\ten,")
w(f"\t\t\t\tBase,")
w(f"\t\t\t\t\"zh-Hans\",")
w(f"\t\t\t);")
w(f"\t\t\tmainGroup = {MAIN_GROUP_ID};")
w(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID} /* Products */;")
w(f"\t\t\tprojectDirPath = \"\";")
w(f"\t\t\tprojectRoot = \"\";")
w(f"\t\t\ttargets = (")
w(f"\t\t\t\t{TARGET_ID} /* CoolBar */,")
w(f"\t\t\t);")
w(f"\t\t}};")
w()

# --- PBXSourcesBuildPhase ---
w(f"\t\t{SOURCES_BUILD_PHASE_ID} /* Sources */ = {{")
w(f"\t\t\tisa = PBXSourcesBuildPhase;")
w(f"\t\t\tbuildActionMask = 2147483647;")
w(f"\t\t\tfiles = (")
for f in source_files:
    w(f"\t\t\t\t{build_files[f]} /* {os.path.basename(f)} in Sources */,")
w(f"\t\t\t);")
w(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w(f"\t\t}};")
w()

# --- PBXFrameworksBuildPhase ---
w(f"\t\t{FRAMEWORKS_BUILD_PHASE_ID} /* Frameworks */ = {{")
w(f"\t\t\tisa = PBXFrameworksBuildPhase;")
w(f"\t\t\tbuildActionMask = 2147483647;")
w(f"\t\t\tfiles = (")
w(f"\t\t\t);")
w(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w(f"\t\t}};")
w()

# --- PBXResourcesBuildPhase ---
w(f"\t\t{RESOURCES_BUILD_PHASE_ID} /* Resources */ = {{")
w(f"\t\t\tisa = PBXResourcesBuildPhase;")
w(f"\t\t\tbuildActionMask = 2147483647;")
w(f"\t\t\tfiles = (")
for f in resource_files:
    w(f"\t\t\t\t{build_files[f]} /* {os.path.basename(f)} in Resources */,")
w(f"\t\t\t);")
w(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
w(f"\t\t}};")
w()

# --- Build Configurations ---
def write_config(uid, name, is_project=True):
    w(f"\t\t{uid} /* {name} */ = {{")
    w(f"\t\t\tisa = XCBuildConfiguration;")
    if is_project:
        base_sdk = "macosx"
        settings = [
            ('ALWAYS_SEARCH_USER_PATHS', 'NO'),
            ('CLANG_ANALYZER_NONNULL', 'YES'),
            ('CLANG_CXX_LANGUAGE_STANDARD', '"gnu++20"'),
            ('CLANG_ENABLE_MODULES', 'YES'),
            ('CLANG_ENABLE_OBJC_ARC', 'YES'),
            ('COPY_PHASE_STRIP', 'NO'),
            ('DEBUG_INFORMATION_FORMAT', 'dwarf' if name == 'Debug' else '"dwarf-with-dsym"'),
            ('ENABLE_STRICT_OBJC_MSGSEND', 'YES'),
            ('ENABLE_TESTABILITY', 'YES' if name == 'Debug' else 'NO'),
            ('GCC_DYNAMIC_NO_PIC', 'NO'),
            ('GCC_OPTIMIZATION_LEVEL', '0' if name == 'Debug' else 's'),
            ('GCC_PREPROCESSOR_DEFINITIONS', 'DEBUG=1 ' if name == 'Debug' else ''),
            ('MACOSX_DEPLOYMENT_TARGET', '14.0'),
            ('MTL_ENABLE_DEBUG_INFO', 'INCLUDE_SOURCE' if name == 'Debug' else 'NO'),
            ('ONLY_ACTIVE_ARCH', 'YES' if name == 'Debug' else 'NO'),
            ('SDKROOT', 'macosx'),
            ('SWIFT_ACTIVE_COMPILATION_CONDITIONS', 'DEBUG' if name == 'Debug' else ''),
            ('SWIFT_OPTIMIZATION_LEVEL', '"-O"' if name != 'Debug' else '"-Onone"'),
            ('SWIFT_VERSION', '5.0'),
        ]
    else:
        settings = [
            ('ASSETCATALOG_COMPILER_APPICON_NAME', 'AppIcon'),
            ('CODE_SIGN_STYLE', 'Automatic'),
            ('COMBINE_HIDPI_IMAGES', 'YES'),
            ('CURRENT_PROJECT_VERSION', '1'),
            ('ENABLE_HARDENED_RUNTIME', 'YES'),
            ('GENERATE_INFOPLIST_FILE', 'YES'),
            ('INFOPLIST_FILE', 'Resources/Info.plist'),
            ('INFOPLIST_KEY_LSUIElement', 'YES'),
            ('INFOPLIST_KEY_NSHumanReadableCopyright', ''),
            ('LD_RUNPATH_SEARCH_PATHS', '"$(inherited) @executable_path/../Frameworks"'),
            ('MARKETING_VERSION', '1.0.0'),
            ('PRODUCT_BUNDLE_IDENTIFIER', 'com.coolbar.app'),
            ('PRODUCT_NAME', '"$(TARGET_NAME)"'),
            ('SWIFT_EMIT_LOC_STRINGS', 'YES'),
            ('SWIFT_VERSION', '5.0'),
        ]

    w(f"\t\t\tbuildSettings = {{")
    for key, val in settings:
        w(f"\t\t\t\t{key} = {val};")
    w(f"\t\t\t}};")
    w(f"\t\t\tname = {name};")
    w(f"\t\t}};")
    w()

write_config(BUILD_CONFIG_DEBUG_PROJ, "Debug", is_project=True)
write_config(BUILD_CONFIG_RELEASE_PROJ, "Release", is_project=True)
write_config(BUILD_CONFIG_DEBUG_TARGET, "Debug", is_project=False)
write_config(BUILD_CONFIG_RELEASE_TARGET, "Release", is_project=False)

# --- XCConfigurationList ---
for uid, name, configs in [
    (BUILD_CONFIG_LIST_PROJ, "project", [BUILD_CONFIG_DEBUG_PROJ, BUILD_CONFIG_RELEASE_PROJ]),
    (BUILD_CONFIG_LIST_TARGET, "target", [BUILD_CONFIG_DEBUG_TARGET, BUILD_CONFIG_RELEASE_TARGET]),
]:
    w(f"\t\t{uid} /* Build configuration list for PBX{name.capitalize()} \"CoolBar\" */ = {{")
    w(f"\t\t\tisa = XCConfigurationList;")
    w(f"\t\t\tbuildConfigurations = (")
    for c in configs:
        w(f"\t\t\t\t{c} /* Debug */," if "debug" in c.lower() else f"\t\t\t\t{c} /* Release */,")
    w(f"\t\t\t);")
    w(f"\t\t\tdefaultConfigurationIsVisible = 0;")
    w(f"\t\t\tdefaultConfigurationName = Release;")
    w(f"\t\t}};")
    w()

# Close objects
w(f"\t}};")
# Root object ref
w(f"\trootObject = {PROJ_ID} /* Project object */;")
w("}")

# Write pbxproj
pbxproj_path = os.path.join(XCODEPROJ_DIR, "project.pbxproj")
with open(pbxproj_path, "w") as f:
    f.write("\n".join(lines))

print(f"\nGenerated: {pbxproj_path}")
print(f"  Source files: {len(source_files)}")
print(f"  Resource files: {len(resource_files)}")
