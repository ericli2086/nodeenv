#!/usr/bin/env bash

# NodeEnv: Project-Level Node.js Version Management Tool

NODEENV_ROOT=$(cd "$(dirname "$(readlink -f ${BASH_SOURCE[0]})")" && pwd)
NODEENV_VERSIONS="${NODEENV_ROOT}/versions"
VERSION_FILE=".node-version"

# Detect system architecture
detect_arch() {
    local arch=$(uname -m)
    case "${arch}" in
        x86_64) echo "x64" ;;
        aarch64) echo "arm64" ;;
        *) echo "unsupported"; return 1 ;;
    esac
}

# Install a specific Node.js version
nodeenv_install() {
    local version="$1"
    local arch=$(detect_arch)
    
    if [[ -z "${version}" ]]; then
        echo "Usage: nodeenv install <version>"
        return 1
    fi 
    
    local install_path="${NODEENV_VERSIONS}/node-v${version}"
    local download_url="https://nodejs.org/dist/v${version}/node-v${version}-linux-${arch}.tar.xz"
    
    if [[ -d "${install_path}" ]]; then
        echo "Node.js ${version} is already installed."
        return 0
    fi
    
    echo "Downloading Node.js ${version}..."
    mkdir -p "${install_path}"
    curl -L "${download_url}" | tar -xJ --strip-components=1 -C "${install_path}"
    
    echo "Node.js ${version} installed successfully."
}

# List installed versions
nodeenv_versions() {
    [[ -d ${NODEENV_VERSIONS} ]] && ls "${NODEENV_VERSIONS}"
}

# Set local version for current project
nodeenv_local() {
    local version="$1"
    
    if [[ -z "${version}" ]]; then
        # If no version provided, read current project's version
        if [[ -f "${VERSION_FILE}" ]]; then
            cat "${VERSION_FILE}"
            return 0
        else
            echo "No local version set. Usage: nodeenv local <version>"
            return 1
        fi
    fi
    
    # Check if version is installed
    local install_path="${NODEENV_VERSIONS}/node-v${version}"
    if [[ ! -d "${install_path}" ]]; then
        echo "Node.js ${version} is not installed. Install it first with 'nodeenv install ${version}'"
        return 1
    fi
    
    # Write version to .node-version file
    echo "${version}" > "${VERSION_FILE}"
    echo "Local version set to ${version}"
}

# Automatically select Node.js version for current project
select_project_node_version() {
    local current_dir="$PWD"
    
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "${current_dir}/${VERSION_FILE}" ]]; then
            local version=$(cat "${current_dir}/${VERSION_FILE}")
            local install_path="${NODEENV_VERSIONS}/node-v${version}"
            if [[ -d "${install_path}" ]]; then
                echo ${install_path}/bin
                return 0
            else
                return 1
            fi
        fi
        current_dir=$(dirname "$current_dir")
    done
    
    # No version file found, use system default
    return 1
}

# Setup hook for shell
setup_shell_hook() {
    echo "# Add to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "# NodeEnv Project Version Hook"
    echo "nodeenv_auto_select() {"
    echo "    if [[ ! -f ~/.nodeenv_path_bak ]]; then"
    echo "        echo \$PATH > ~/.nodeenv_path_bak"
    echo "    fi"
    echo "    "
    echo "    nodepath=\$(nodeenv switch 2>/dev/null)"
    echo "    if [[ \"\$PATH\" =~ \"\${nodepath}\" ]]; then"
    echo "        nodepath=\"\""
    echo "    fi"
    echo "    "
    echo "    if [[ \"\${nodepath}\" != \"\" ]]; then"
    echo "        export PATH=\${nodepath}:\$(cat ~/.nodeenv_path_bak)"
    echo "    else"
    echo "        export PATH=\$(cat ~/.nodeenv_path_bak)"
    echo "    fi"
    echo "}"
    echo ""
    echo "env_auto_select() {"
    echo "    nodeenv_auto_select"
    echo "}"
    echo "PROMPT_COMMAND=\"env_auto_select\""
}

# Uninstall a specific Node.js version
nodeenv_uninstall() {
    local version="$1"
    local install_path="${NODEENV_VERSIONS}/node-v${version}"
    
    if [[ ! -d "${install_path}" ]]; then
        echo "Node.js ${version} is not installed."
        return 1
    fi
    
    # Remove version directory
    rm -rf "${install_path}"
    
    echo "Node.js ${version} uninstalled successfully."
}

# Main command dispatcher
nodeenv() {
    local command="$1"
    shift
    
    case "${command}" in
        install) nodeenv_install "$@" ;;
        versions) nodeenv_versions ;;
        local) nodeenv_local "$@" ;;
        uninstall) nodeenv_uninstall "$@" ;;
        setup) setup_shell_hook ;;
        switch) select_project_node_version ;;
        *) 
            echo "Usage: nodeenv [install|versions|local|uninstall|setup]"
            return 1
            ;;
    esac
}

nodeenv "$@"
