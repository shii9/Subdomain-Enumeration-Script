#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
#  WEB_SUB - Professional Subdomain Enumeration Tool
#  Version: 6.0 - Maximum Aggressive Mode
#  Usage: web_sub <target.com> [tool_flags] [-all for processing]
#═══════════════════════════════════════════════════════════════════════════

set -o pipefail

VERSION="6.0"

# ── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ── Indicators ────────────────────────────────────────────────────────────
INFO="${BLUE}[ℹ]${NC}"
SUCCESS="${GREEN}[✓]${NC}"
ERROR="${RED}[✗]${NC}"
WARNING="${YELLOW}[⚠]${NC}"
PROGRESS="${CYAN}[⟳]${NC}"
TARGET_ICON="${WHITE}[◉]${NC}"

# ── Global Config ────────────────────────────────────────────────────────
TARGET=""
WORK_DIR=""
THREADS=50
WORDLIST=""

# ── Tool Flags ───────────────────────────────────────────────────────────
USE_ALL_TOOLS=false
USE_SUBFINDER=false
USE_ASSETFINDER=false
USE_AMASS=false
USE_FINDOMAIN=false
USE_CRTSH=false
USE_CHAOS=false
USE_SHUFFLEDNS=false
USE_PUREDNS=false

# ── Processing Flags ─────────────────────────────────────────────────────
DO_ALL_PROCESSING=false

# ── Counters ─────────────────────────────────────────────────────────────
declare -A TOOL_COUNTS
TOOLS_SELECTED=()

#═══════════════════════════════════════════════════════════════════════════
# BANNER
#═══════════════════════════════════════════════════════════════════════════

banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   ██╗    ██╗███████╗██████╗      ███████╗██╗   ██╗██████╗            ║
║   ██║    ██║██╔════╝██╔══██╗     ██╔════╝██║   ██║██╔══██╗           ║
║   ██║ █╗ ██║█████╗  ██████╔╝     ███████╗██║   ██║██████╔╝           ║
║   ██║███╗██║██╔══╝  ██╔══██╗     ╚════██║██║   ██║██╔══██╗           ║
║   ╚███╔███╔╝███████╗██████╔╝     ███████║╚██████╔╝██████╔╝           ║
║    ╚══╝╚══╝ ╚══════╝╚═════╝      ╚══════╝ ╚═════╝ ╚═════╝            ║
║                                                                      ║
║           Professional Subdomain Enumeration Tool  v6.0              ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#═══════════════════════════════════════════════════════════════════════════
# HELP
#═══════════════════════════════════════════════════════════════════════════

show_help() {
    echo -e "${WHITE}${BOLD}USAGE:${NC}"
    echo -e "  web_sub <target.com> [tool_options] [processing_options]\n"

    echo -e "${WHITE}${BOLD}COLLECTION OPTIONS (pick one or more):${NC}"
    echo -e "  ${GREEN}-all${NC}              Use ALL available tools"
    echo -e "  ${GREEN}-subfinder${NC}        Subfinder — passive multi-source enumeration"
    echo -e "  ${GREEN}-assetfinder${NC}      Assetfinder — fast passive enumeration"
    echo -e "  ${GREEN}-amass${NC}            Amass — deep passive enumeration (slow)"
    echo -e "  ${GREEN}-findomain${NC}        Findomain — passive multi-source"
    echo -e "  ${GREEN}-crtsh${NC}            crt.sh — Certificate Transparency logs"
    echo -e "  ${GREEN}-chaos${NC}            Chaos — ProjectDiscovery dataset"
    echo -e "  ${GREEN}-shuffledns${NC}       ShuffleDNS — DNS brute-force (needs -w)"
    echo -e "  ${GREEN}-puredns${NC}          Puredns — wildcard-aware DNS brute-force (needs -w)\n"

    echo -e "${WHITE}${BOLD}PROCESSING OPTIONS:${NC}"
    echo -e "  ${CYAN}-all${NC}               (2nd -all flag) Run all processing steps:"
    echo -e "                     → Merge  → Normalize  → Live Check\n"

    echo -e "${WHITE}${BOLD}ADDITIONAL OPTIONS:${NC}"
    echo -e "  ${CYAN}-w, --wordlist${NC}     Wordlist path (required for shuffledns/puredns)"
    echo -e "  ${CYAN}-t, --threads${NC}      httpx threads (default: 50)"
    echo -e "                     ${YELLOW}-t 25${NC}  → slow/stable"
    echo -e "                     ${YELLOW}-t 50${NC}  → balanced (default)"
    echo -e "                     ${YELLOW}-t 100${NC} → aggressive"
    echo -e "  ${CYAN}-h, --help${NC}         Show this help\n"

    echo -e "${WHITE}${BOLD}EXAMPLES:${NC}"
    echo -e "  ${YELLOW}# Collect from all tools, no processing${NC}"
    echo -e "  web_sub example.com -all\n"
    echo -e "  ${YELLOW}# Collect from all tools + merge + normalize + live check${NC}"
    echo -e "  web_sub example.com -all -all\n"
    echo -e "  ${YELLOW}# Subfinder only (auto runs normalize + live check, no merge needed)${NC}"
    echo -e "  web_sub example.com -subfinder -all\n"
    echo -e "  ${YELLOW}# Amass only + full processing${NC}"
    echo -e "  web_sub example.com -amass -all\n"
    echo -e "  ${YELLOW}# crt.sh only + full processing${NC}"
    echo -e "  web_sub example.com -crtsh -all\n"
    echo -e "  ${YELLOW}# Multiple tools + full processing${NC}"
    echo -e "  web_sub example.com -subfinder -assetfinder -crtsh -all\n"
    echo -e "  ${YELLOW}# ShuffleDNS brute-force + full processing${NC}"
    echo -e "  web_sub example.com -shuffledns -w /opt/wordlists/subdomains.txt -all\n"
    echo -e "  ${YELLOW}# All tools + aggressive threads + full processing${NC}"
    echo -e "  web_sub example.com -all -all -t 100\n"

    echo -e "${WHITE}${BOLD}OUTPUT STRUCTURE:${NC}"
    echo -e "  subdomain_example.com/"
    echo -e "  ├── ${CYAN}subfinder.txt${NC}              Subfinder raw results"
    echo -e "  ├── ${CYAN}assetfinder.txt${NC}            Assetfinder raw results"
    echo -e "  ├── ${CYAN}amass.txt${NC}                  Amass raw results"
    echo -e "  ├── ${CYAN}findomain.txt${NC}              Findomain raw results"
    echo -e "  ├── ${CYAN}crtsh.txt${NC}                  crt.sh raw results"
    echo -e "  ├── ${CYAN}chaos.txt${NC}                  Chaos raw results"
    echo -e "  ├── ${CYAN}shuffledns.txt${NC}             ShuffleDNS raw results"
    echo -e "  ├── ${CYAN}puredns.txt${NC}                Puredns raw results"
    echo -e "  ├── ${CYAN}all_subdomains.txt${NC}         Combined (before dedup)"
    echo -e "  ├── ${CYAN}merged_subdomains.txt${NC}      Merged & deduplicated"
    echo -e "  ├── ${CYAN}normalized_subdomains.txt${NC}  Cleaned & validated"
    echo -e "  ├── ${CYAN}alive_subdomains.txt${NC}       Live hosts (200, 301, 302)"
    echo -e "  ├── ${CYAN}not_found_subdomains.txt${NC}   404 responses"
    echo -e "  ├── ${CYAN}other_status_subdomains.txt${NC} Other status codes"
    echo -e "  └── ${CYAN}SUMMARY_REPORT.txt${NC}         Full summary\n"

    echo -e "${WHITE}${BOLD}HOW MERGE WORKS:${NC}"
    echo -e "  • Single tool selected   → No merge step, goes straight to normalize"
    echo -e "  • Multiple tools selected → Merge step runs to combine & deduplicate\n"

    echo -e "${WHITE}${BOLD}NOTES:${NC}"
    echo -e "  • Subdomain lists are NOT printed to terminal during collection"
    echo -e "  • -all (1st)  = select all tools"
    echo -e "  • -all (2nd)  = run all processing steps"
    echo -e "  • shuffledns and puredns require -w wordlist flag"
    echo -e "  • Output directory: subdomain_<target.com>/\n"

    echo -e "${WHITE}Version:${NC} $VERSION"
    echo -e "${WHITE}Author:${NC}  Professional Bug Hunter\n"
}

#═══════════════════════════════════════════════════════════════════════════
# UTILITY
#═══════════════════════════════════════════════════════════════════════════

log() {
    local level=$1; shift
    local msg="$@"
    case $level in
        INFO)     echo -e "${INFO} ${msg}" ;;
        SUCCESS)  echo -e "${SUCCESS} ${msg}" ;;
        ERROR)    echo -e "${ERROR} ${msg}" ;;
        WARN)     echo -e "${WARNING} ${msg}" ;;
        PROGRESS) echo -e "${PROGRESS} ${msg}" ;;
        TARGET)   echo -e "${TARGET_ICON} ${msg}" ;;
    esac
}

# Spinner: shows animated progress, then prints [✓] done on finish
spinner() {
    local pid=$1
    local msg=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    # Hide cursor
    tput civis 2>/dev/null

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r${CYAN}[${spin:$i:1}]${NC} %s" "$msg"
        sleep 0.1
    done

    printf "\r${SUCCESS} %s\n" "$msg"

    # Restore cursor
    tput cnorm 2>/dev/null
}

check_tool() {
    command -v "$1" &>/dev/null
}

count_lines() {
    local file="$1"
    if [ -f "$file" ]; then
        wc -l < "$file" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

setup_workspace() {
    WORK_DIR="subdomain_${TARGET}"

    if [ ! -d "$WORK_DIR" ]; then
        mkdir -p "$WORK_DIR"
        log SUCCESS "Created directory: ${CYAN}${WORK_DIR}/${NC}"
    else
        log INFO "Using existing directory: ${CYAN}${WORK_DIR}/${NC}"
    fi

    # Write resolvers
    cat > "$WORK_DIR/resolvers.txt" << 'EOF'
1.1.1.1
8.8.8.8
8.8.4.4
1.0.0.1
9.9.9.9
149.112.112.112
208.67.222.222
208.67.220.220
64.6.64.6
64.6.65.6
EOF
}

#═══════════════════════════════════════════════════════════════════════════
# COLLECTION FUNCTIONS
# Each tool runs silently, writes to its own file, counts results
#═══════════════════════════════════════════════════════════════════════════

collect_subfinder() {
    local out="$WORK_DIR/subfinder.txt"

    log PROGRESS "Running subfinder..."

    if ! check_tool "subfinder"; then
        log WARN "subfinder not installed — skipping"
        return
    fi

    (
        # Strategy 1: Maximum sources + recursive discovery
        subfinder -d "$TARGET" -all -recursive -silent 2>/dev/null

        # Strategy 2: All sources + resolve with custom resolvers
        subfinder -d "$TARGET" -all -nW -rL "$WORK_DIR/resolvers.txt" -silent 2>/dev/null

        # Strategy 3: Specific high-quality sources (fast + reliable)
        subfinder -d "$TARGET" -sources censys,virustotal,crtsh,hackertarget,shodan -silent 2>/dev/null

        # Strategy 4: Rate-limited for stability
        subfinder -d "$TARGET" -all -t 50 -rate-limit 100 -silent 2>/dev/null

    ) 2>/dev/null | sort -u > "$out" &

    spinner $! "Subdomain collection for subfinder (4 strategies)..."

    local count
    count=$(count_lines "$out")
    TOOL_COUNTS[subfinder]=$count
    log SUCCESS "Subfinder: ${CYAN}${count}${NC} subdomains"
}

collect_assetfinder() {
    local out="$WORK_DIR/assetfinder.txt"

    log PROGRESS "Running assetfinder..."

    if ! check_tool "assetfinder"; then
        log WARN "assetfinder not installed — skipping"
        return
    fi

    (
        # Strategy 1: Basic subdomain-only collection
        assetfinder --subs-only "$TARGET" 2>/dev/null

        # Strategy 2: With filtering and sorting
        assetfinder --subs-only "$TARGET" 2>/dev/null | grep -v "\*" 

    ) 2>/dev/null | sort -u > "$out" &

    spinner $! "Subdomain collection for assetfinder (2 strategies)..."

    local count
    count=$(count_lines "$out")
    TOOL_COUNTS[assetfinder]=$count
    log SUCCESS "Assetfinder: ${CYAN}${count}${NC} subdomains"
}

collect_amass() {
    local out="$WORK_DIR/amass.txt"

    log PROGRESS "Running amass (passive, up to 15 min)..."

    if ! check_tool "amass"; then
        log WARN "amass not installed — skipping"
        return
    fi

    (
        timeout 900 amass enum -passive -d "$TARGET" \
            -nocolor 2>/dev/null \
            | grep -E "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$" \
            | grep "\.${TARGET}$"
    ) | sort -u > "$out" &

    spinner $! "Subdomain collection for amass (may take longer)..."

    local count
    count=$(count_lines "$out")
    TOOL_COUNTS[amass]=$count
    log SUCCESS "Amass: ${CYAN}${count}${NC} subdomains"
}

collect_findomain() {
    local out="$WORK_DIR/findomain.txt"

    log PROGRESS "Running findomain..."

    if ! check_tool "findomain"; then
        log WARN "findomain not installed — skipping"
        return
    fi

    (
        findomain -t "$TARGET" -q 2>/dev/null \
            | grep -v '^$' \
            | grep "\.${TARGET}$"
    ) | sort -u > "$out" &

    spinner $! "Subdomain collection for findomain..."

    local count
    count=$(count_lines "$out")
    TOOL_COUNTS[findomain]=$count
    if [ "$count" -gt 0 ]; then
        log SUCCESS "Findomain: ${CYAN}${count}${NC} subdomains"
    else
        log INFO "Findomain: No results found"
    fi
}

collect_crtsh() {
    local out="$WORK_DIR/crtsh.txt"
    local tmp1="$WORK_DIR/.crtsh_1.tmp"
    local tmp2="$WORK_DIR/.crtsh_2.tmp"
    local tmp3="$WORK_DIR/.crtsh_3.tmp"
    local tmp4="$WORK_DIR/.crtsh_4.tmp"

    log PROGRESS "Running crt.sh..."

    (
        # Query 1: wildcard
        curl -s --max-time 30 \
            "https://crt.sh/?q=%.${TARGET}&output=json" 2>/dev/null \
            | jq -r '.[].name_value' 2>/dev/null \
            | sed 's/\*\.//g' > "$tmp1"

        # Query 2: identity
        curl -s --max-time 30 \
            "https://crt.sh/?Identity=${TARGET}&output=json" 2>/dev/null \
            | jq -r '.[].name_value' 2>/dev/null \
            | sed 's/\*\.//g' > "$tmp2"

        # Query 3: common name + SAN
        curl -s --max-time 30 \
            "https://crt.sh/?q=%.${TARGET}&output=json" 2>/dev/null \
            | jq -r '.[] | .common_name, .name_value' 2>/dev/null \
            | sed 's/\*\.//g' > "$tmp3"

        # Query 4: direct
        curl -s --max-time 30 \
            "https://crt.sh/?q=${TARGET}&output=json" 2>/dev/null \
            | jq -r '.[].name_value' 2>/dev/null \
            | tr ',' '\n' \
            | sed 's/\*\.//g' > "$tmp4"

        cat "$tmp1" "$tmp2" "$tmp3" "$tmp4" 2>/dev/null \
            | grep -v '^$' \
            | sort -u

        rm -f "$tmp1" "$tmp2" "$tmp3" "$tmp4"
    ) > "$out" &

    spinner $! "Subdomain collection for crt.sh (4 queries)..."

    local count
    count=$(count_lines "$out")
    TOOL_COUNTS[crtsh]=$count
    if [ "$count" -gt 0 ]; then
        log SUCCESS "Crt.sh: ${CYAN}${count}${NC} subdomains"
    else
        log INFO "Crt.sh: No results found"
    fi
}

collect_chaos() {
    local out="$WORK_DIR/chaos.txt"

    log PROGRESS "Running Chaos dataset..."

    (
        curl -s --max-time 30 \
            "https://chaos-data.projectdiscovery.io/index.json" 2>/dev/null \
            | jq -r --arg t "$TARGET" '.[] | select(.URL | contains($t)) | .URL' 2>/dev/null \
            | xargs -I{} curl -s --max-time 20 {} 2>/dev/null \
            | grep "\.${TARGET}$" \
            | sort -u
    ) > "$out" &

    spinner $! "Subdomain collection for Chaos..."

    local count
    count=$(count_lines "$out")
    TOOL_COUNTS[chaos]=$count
    if [ "$count" -gt 0 ]; then
        log SUCCESS "Chaos: ${CYAN}${count}${NC} subdomains"
    else
        log INFO "Chaos: No data available for this target"
    fi
}

collect_shuffledns() {
    local out="$WORK_DIR/shuffledns.txt"

    log PROGRESS "Running ShuffleDNS..."

    if ! check_tool "shuffledns"; then
        log WARN "shuffledns not installed — skipping"
        return
    fi

    if [ -z "$WORDLIST" ] || [ ! -f "$WORDLIST" ]; then
        log ERROR "ShuffleDNS requires -w <wordlist> — skipping"
        return
    fi

    (
        shuffledns -d "$TARGET" \
            -w "$WORDLIST" \
            -r "$WORK_DIR/resolvers.txt" \
            -t 10000 \
            -silent 2>/dev/null \
            | sort -u
    ) > "$out" &

    spinner $! "Subdomain collection for ShuffleDNS (DNS brute-force)..."

    local count
    count=$(count_lines "$out")
    TOOL_COUNTS[shuffledns]=$count
    log SUCCESS "ShuffleDNS: ${CYAN}${count}${NC} subdomains"
}

collect_puredns() {
    local out="$WORK_DIR/puredns.txt"

    log PROGRESS "Running Puredns..."

    if ! check_tool "puredns"; then
        log WARN "puredns not installed — skipping"
        return
    fi

    if [ -z "$WORDLIST" ] || [ ! -f "$WORDLIST" ]; then
        log ERROR "Puredns requires -w <wordlist> — skipping"
        return
    fi

    (
        puredns bruteforce "$WORDLIST" "$TARGET" \
            -r "$WORK_DIR/resolvers.txt" \
            --wildcard-tests 25 \
            2>/dev/null \
            | sort -u
    ) > "$out" &

    spinner $! "Subdomain collection for Puredns (wildcard-aware)..."

    local count
    count=$(count_lines "$out")
    TOOL_COUNTS[puredns]=$count
    log SUCCESS "Puredns: ${CYAN}${count}${NC} subdomains"
}

#═══════════════════════════════════════════════════════════════════════════
# PROCESSING FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════

# Merge: only runs when multiple tool output files exist
do_merge() {
    # Collect existing non-empty tool files
    local tool_files=()
    for tool in subfinder assetfinder amass findomain crtsh chaos shuffledns puredns; do
        local f="$WORK_DIR/${tool}.txt"
        if [ -f "$f" ] && [ -s "$f" ]; then
            tool_files+=("$f")
        fi
    done

    local file_count=${#tool_files[@]}

    if [ "$file_count" -eq 0 ]; then
        log ERROR "No tool output files found. Cannot merge."
        return 1
    fi

    if [ "$file_count" -eq 1 ]; then
        # Single tool — just copy, no need to merge
        log INFO "Single tool used — skipping merge, using tool output directly"
        cp "${tool_files[0]}" "$WORK_DIR/merged_subdomains.txt"
        local count
        count=$(count_lines "$WORK_DIR/merged_subdomains.txt")
        log SUCCESS "Marge domain: ${CYAN}${count}${NC} subdomains"
        return 0
    fi

    log PROGRESS "Merging results from ${file_count} tools..."

    # Combine all → all_subdomains.txt (raw, may have dupes)
    cat "${tool_files[@]}" 2>/dev/null \
        | grep -v '^$' \
        | sort > "$WORK_DIR/all_subdomains.txt"

    local all_count
    all_count=$(count_lines "$WORK_DIR/all_subdomains.txt")
    log SUCCESS "All domain: ${CYAN}${all_count}${NC} subdomains"

    # Deduplicate → merged_subdomains.txt
    sort -u "$WORK_DIR/all_subdomains.txt" > "$WORK_DIR/merged_subdomains.txt"

    local merged_count
    merged_count=$(count_lines "$WORK_DIR/merged_subdomains.txt")
    log SUCCESS "Marge domain: ${CYAN}${merged_count}${NC} subdomains"
}

# Normalize: clean garbage, validate format, filter to target only
do_normalize() {
    # Pick input: prefer merged, fallback to first available tool file
    local input_file="$WORK_DIR/merged_subdomains.txt"

    if [ ! -s "$input_file" ]; then
        for tool in subfinder assetfinder amass findomain crtsh chaos shuffledns puredns; do
            local f="$WORK_DIR/${tool}.txt"
            if [ -f "$f" ] && [ -s "$f" ]; then
                input_file="$f"
                break
            fi
        done
    fi

    if [ ! -f "$input_file" ] || [ ! -s "$input_file" ]; then
        log ERROR "No subdomain data found to normalize"
        return 1
    fi

    log PROGRESS "Normalizing subdomains..."

    (
        cat "$input_file" | \
        # Trim whitespace
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
        # Remove empty lines
        sed '/^$/d' | \
        # Strip http/https prefix
        sed -E 's#https?://##I' | \
        # Strip www. prefix
        sed -E 's#^www\.##I' | \
        # Strip port numbers
        sed 's/:[0-9]*$//' | \
        # Lowercase
        tr '[:upper:]' '[:lower:]' | \
        # Remove wildcard prefixes
        sed 's/\*\.//g' | \
        # Remove leading dots
        sed 's/^\.//g' | \
        # Remove trailing dots
        sed 's/\.$//' | \
        # Remove amass noise
        grep -v "Netblock" | \
        grep -v "IPAddress" | \
        grep -v "contains" | \
        grep -v "^AS[0-9]" | \
        grep -v "^---" | \
        grep -v "CIDR" | \
        # Remove raw IPs
        grep -Ev '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$' | \
        # Validate domain format (must have at least one dot, no bad chars)
        grep -E '^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$' | \
        # Keep only subdomains of the target
        grep "\.${TARGET}$\|^${TARGET}$" | \
        sort -u
    ) > "$WORK_DIR/normalized_subdomains.txt"

    local count
    count=$(count_lines "$WORK_DIR/normalized_subdomains.txt")
    log SUCCESS "Normalized domain: ${CYAN}${count}${NC} subdomains"
}

# Live check: httpx probes, splits into alive / 404 / other
do_live_check() {
    if ! check_tool "httpx"; then
        log WARN "httpx not installed — skipping live check"
        return
    fi

    # Pick input: prefer normalized
    local input_file=""
    for f in \
        "$WORK_DIR/normalized_subdomains.txt" \
        "$WORK_DIR/merged_subdomains.txt" \
        "$WORK_DIR/all_subdomains.txt"; do
        if [ -f "$f" ] && [ -s "$f" ]; then
            input_file="$f"
            break
        fi
    done

    if [ -z "$input_file" ]; then
        # Fallback to first available tool file
        for tool in subfinder assetfinder amass findomain crtsh chaos shuffledns puredns; do
            local f="$WORK_DIR/${tool}.txt"
            if [ -f "$f" ] && [ -s "$f" ]; then
                input_file="$f"
                break
            fi
        done
    fi

    if [ -z "$input_file" ]; then
        log ERROR "No subdomain data found for live check"
        return
    fi

    log PROGRESS "Checking live subdomains with httpx..."

    local json_out="$WORK_DIR/.httpx_results.json"

    (
        cat "$input_file" | \
            httpx \
                -silent \
                -threads "$THREADS" \
                -status-code \
                -no-color \
                -json \
                2>/dev/null
    ) > "$json_out" &

    spinner $! "Live host probing (threads: ${THREADS})..."

    if [ ! -f "$json_out" ] || [ ! -s "$json_out" ]; then
        log WARN "httpx returned no results"
        return
    fi

    # ── Alive: 200, 301, 302 ─────────────────────────────────────────────
    jq -r 'select(
        .status_code == 200 or
        .status_code == 301 or
        .status_code == 302
    ) | .url' "$json_out" 2>/dev/null \
        | sort -u > "$WORK_DIR/alive_subdomains.txt"

    # ── Not Found: 404 ───────────────────────────────────────────────────
    jq -r 'select(.status_code == 404) | .url' \
        "$json_out" 2>/dev/null \
        | sort -u > "$WORK_DIR/not_found_subdomains.txt"

    # ── Other status codes ───────────────────────────────────────────────
    jq -r 'select(
        .status_code != 200 and
        .status_code != 301 and
        .status_code != 302 and
        .status_code != 404
    ) | "\(.status_code) \(.url)"' "$json_out" 2>/dev/null \
        | sort -u > "$WORK_DIR/other_status_subdomains.txt"

    # Remove temp JSON
    rm -f "$json_out"

    local alive_count not_found_count other_count not_alive_count
    alive_count=$(count_lines "$WORK_DIR/alive_subdomains.txt")
    not_found_count=$(count_lines "$WORK_DIR/not_found_subdomains.txt")
    other_count=$(count_lines "$WORK_DIR/other_status_subdomains.txt")
    not_alive_count=$((not_found_count + other_count))

    log SUCCESS "Alive domain: ${CYAN}${alive_count}${NC} subdomains (200, 301, 302)"
    log SUCCESS "Not Alive domain: ${CYAN}${not_alive_count}${NC} subdomains (404 & other)"
}

#═══════════════════════════════════════════════════════════════════════════
# SUMMARY REPORT
#═══════════════════════════════════════════════════════════════════════════

generate_summary() {
    local report="$WORK_DIR/SUMMARY_REPORT.txt"

    {
        cat << EOF
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║                    WEB_SUB ENUMERATION SUMMARY                         ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝

Target:           $TARGET
Scan Date:        $(date)
Output Directory: $WORK_DIR/
Version:          $VERSION
Threads:          $THREADS


═══════════════════════════════════════════════════════════════════════════
 PER-TOOL RESULTS
═══════════════════════════════════════════════════════════════════════════
EOF

        for tool in subfinder assetfinder amass findomain crtsh chaos shuffledns puredns; do
            if [[ -v "TOOL_COUNTS[$tool]" ]]; then
                printf "  %-20s %8d subdomains\n" "${tool}:" "${TOOL_COUNTS[$tool]}"
            fi
        done

        cat << EOF

═══════════════════════════════════════════════════════════════════════════
 PROCESSING RESULTS
═══════════════════════════════════════════════════════════════════════════
EOF

        for label_file in \
            "All domain:        $WORK_DIR/all_subdomains.txt" \
            "Marge domain:      $WORK_DIR/merged_subdomains.txt" \
            "Normalized domain: $WORK_DIR/normalized_subdomains.txt" \
            "Alive domain:      $WORK_DIR/alive_subdomains.txt" \
            "Not Found (404):   $WORK_DIR/not_found_subdomains.txt" \
            "Other status:      $WORK_DIR/other_status_subdomains.txt"; do

            local label="${label_file%%:*}:"
            local file="${label_file#*:}"
            file="${file## }"
            if [ -f "$file" ]; then
                local c
                c=$(count_lines "$file")
                printf "  %-24s %8d subdomains\n" "$label" "$c"
            fi
        done

        cat << EOF

═══════════════════════════════════════════════════════════════════════════
 OUTPUT FILES
═══════════════════════════════════════════════════════════════════════════

Tool Output Files:
EOF

        for tool in subfinder assetfinder amass findomain crtsh chaos shuffledns puredns; do
            local f="$WORK_DIR/${tool}.txt"
            if [ -f "$f" ] && [ -s "$f" ]; then
                local c
                c=$(count_lines "$f")
                printf "  • %-35s (%d lines)\n" "${tool}.txt" "$c"
            fi
        done

        echo ""
        echo "Processing Files:"

        for fname in \
            "all_subdomains.txt" \
            "merged_subdomains.txt" \
            "normalized_subdomains.txt" \
            "alive_subdomains.txt" \
            "not_found_subdomains.txt" \
            "other_status_subdomains.txt"; do
            local f="$WORK_DIR/$fname"
            if [ -f "$f" ]; then
                local c
                c=$(count_lines "$f")
                printf "  • %-35s (%d lines)\n" "$fname" "$c"
            fi
        done

        cat << EOF

═══════════════════════════════════════════════════════════════════════════
 RECOMMENDED NEXT STEPS
═══════════════════════════════════════════════════════════════════════════

1. Subdomain takeover check:
   cat $WORK_DIR/alive_subdomains.txt | nuclei -t takeovers/

2. Port scanning:
   cat $WORK_DIR/normalized_subdomains.txt | naabu -top-ports 1000

3. URL enumeration:
   cat $WORK_DIR/normalized_subdomains.txt | gau > urls.txt
   cat $WORK_DIR/normalized_subdomains.txt | waybackurls >> urls.txt
   cat $WORK_DIR/alive_subdomains.txt | katana -d 3 -jc >> urls.txt

4. Screenshots:
   cat $WORK_DIR/alive_subdomains.txt | gowitness file -f - -D screenshots/

5. Vulnerability scan:
   cat $WORK_DIR/alive_subdomains.txt | nuclei -t cves/ -t exposures/ -severity critical,high

6. Technology detection:
   cat $WORK_DIR/alive_subdomains.txt | httpx -tech-detect -title -status-code

═══════════════════════════════════════════════════════════════════════════
Report Generated: $(date)
WEB_SUB Version: $VERSION
═══════════════════════════════════════════════════════════════════════════
EOF
    } > "$report"

    log SUCCESS "Summary saved: ${CYAN}$WORK_DIR/SUMMARY_REPORT.txt${NC}"
}

#═══════════════════════════════════════════════════════════════════════════
# COLLECTION RUNNER
#═══════════════════════════════════════════════════════════════════════════

run_collection() {
    echo ""
    log TARGET "Target: ${WHITE}${TARGET}${NC}"
    log INFO "Starting subdomain enumeration..."
    echo ""

    [ "$USE_SUBFINDER" = true ]    && collect_subfinder
    [ "$USE_ASSETFINDER" = true ]  && collect_assetfinder
    [ "$USE_AMASS" = true ]        && collect_amass
    [ "$USE_FINDOMAIN" = true ]    && collect_findomain
    [ "$USE_CRTSH" = true ]        && collect_crtsh
    [ "$USE_CHAOS" = true ]        && collect_chaos
    [ "$USE_SHUFFLEDNS" = true ]   && collect_shuffledns
    [ "$USE_PUREDNS" = true ]      && collect_puredns

    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# PROCESSING RUNNER
#═══════════════════════════════════════════════════════════════════════════

run_processing() {
    # Count how many tool output files actually have content
    local filled_tools=0
    for tool in subfinder assetfinder amass findomain crtsh chaos shuffledns puredns; do
        [ -f "$WORK_DIR/${tool}.txt" ] && [ -s "$WORK_DIR/${tool}.txt" ] && \
            filled_tools=$((filled_tools + 1))
    done

    # Merge (only if multiple tools produced results)
    do_merge

    echo ""

    # Normalize
    do_normalize

    echo ""

    # Live check
    do_live_check

    echo ""
}

#═══════════════════════════════════════════════════════════════════════════
# ARGUMENT PARSER
#═══════════════════════════════════════════════════════════════════════════

parse_args() {
    local all_flag_count=0

    if [ $# -eq 0 ]; then
        banner
        show_help
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                banner
                show_help
                exit 0
                ;;

            # ── -all is dual-purpose ──────────────────────────────────────
            # First occurrence  → select all tools
            # Second occurrence → enable all processing
            -all)
                all_flag_count=$((all_flag_count + 1))
                if [ "$all_flag_count" -eq 1 ]; then
                    USE_ALL_TOOLS=true
                    USE_SUBFINDER=true
                    USE_ASSETFINDER=true
                    USE_AMASS=true
                    USE_FINDOMAIN=true
                    USE_CRTSH=true
                    USE_CHAOS=true
                elif [ "$all_flag_count" -eq 2 ]; then
                    DO_ALL_PROCESSING=true
                fi
                shift
                ;;

            # ── Tool flags ────────────────────────────────────────────────
            -subfinder)    USE_SUBFINDER=true;    shift ;;
            -assetfinder)  USE_ASSETFINDER=true;  shift ;;
            -amass)        USE_AMASS=true;         shift ;;
            -findomain)    USE_FINDOMAIN=true;     shift ;;
            -crtsh)        USE_CRTSH=true;         shift ;;
            -chaos)        USE_CHAOS=true;         shift ;;
            -shuffledns)   USE_SHUFFLEDNS=true;    shift ;;
            -puredns)      USE_PUREDNS=true;       shift ;;

            # ── Config flags ──────────────────────────────────────────────
            -w|--wordlist)
                WORDLIST="$2"
                shift 2
                ;;
            -t|--threads)
                THREADS="$2"
                shift 2
                ;;

            # ── Target ────────────────────────────────────────────────────
            *)
                if [ -z "$TARGET" ]; then
                    TARGET="$1"
                else
                    log ERROR "Unknown argument: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

#═══════════════════════════════════════════════════════════════════════════
# VALIDATION
#═══════════════════════════════════════════════════════════════════════════

validate() {
    if [ -z "$TARGET" ]; then
        log ERROR "No target specified. Example: web_sub example.com -all"
        echo ""
        exit 1
    fi

    # Basic domain format check
    if ! echo "$TARGET" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$'; then
        log ERROR "Invalid domain format: $TARGET"
        exit 1
    fi

    # At least one tool must be selected
    local any_tool=false
    for flag in \
        "$USE_SUBFINDER" "$USE_ASSETFINDER" "$USE_AMASS" \
        "$USE_FINDOMAIN" "$USE_CRTSH" "$USE_CHAOS" \
        "$USE_SHUFFLEDNS" "$USE_PUREDNS"; do
        [ "$flag" = true ] && any_tool=true && break
    done

    if [ "$any_tool" = false ]; then
        log ERROR "No tool selected. Use -all or a specific tool flag (e.g., -subfinder)"
        echo ""
        show_help
        exit 1
    fi

    # Wordlist required for brute-force tools
    if [ "$USE_SHUFFLEDNS" = true ] || [ "$USE_PUREDNS" = true ]; then
        if [ -z "$WORDLIST" ]; then
            log ERROR "ShuffleDNS/Puredns require -w <wordlist>"
            exit 1
        fi
        if [ ! -f "$WORDLIST" ]; then
            log ERROR "Wordlist not found: $WORDLIST"
            exit 1
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════════════
# MAIN
#═══════════════════════════════════════════════════════════════════════════

main() {
    parse_args "$@"
    validate
    banner
    setup_workspace

    # Collect
    run_collection

    # Process if -all (2nd) was given
    if [ "$DO_ALL_PROCESSING" = true ]; then
        run_processing
    fi

    # Report
    generate_summary

    # Final output line
    log SUCCESS "All File Saved in ${CYAN}${WORK_DIR}/${NC} directory"
    echo ""
}

main "$@"
