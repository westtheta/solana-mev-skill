#!/bin/bash

# Solana MEV Skill Installer for Claude Code
# Usage: ./install-custom.sh [--project | --path <path>]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEV_SKILL_NAME="solana-mev"
CORE_SKILL_NAME="solana-dev"
SOURCE_DIR="$SCRIPT_DIR/skill"

PERSONAL_SKILLS_DIR="$HOME/.claude/skills"
PROJECT_SKILLS_DIR=".claude/skills"

INSTALL_BASE=""
MEV_INSTALL_PATH=""
CORE_INSTALL_PATH=""
CORE_SKILL_FOUND=""
CORE_SKILL_LOCATION=""

print_banner() {
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}                                                               ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}███╗   ███╗███████╗██╗   ██╗${NC}                              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}████╗ ████║██╔════╝██║   ██║${NC}                              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}██╔████╔██║█████╗  ██║   ██║${NC}                              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}██║╚██╔╝██║██╔══╝  ╚██╗ ██╔╝${NC}                              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}██║ ╚═╝ ██║███████╗ ╚████╔╝ ${NC}                              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${CYAN}╚═╝     ╚═╝╚══════╝  ╚═══╝  ${NC}                              ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                                               ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}   ${WHITE}Solana MEV Strategy Skill for Claude Code${NC}                   ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                                               ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                                                               ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_help() {
    echo "Solana MEV Skill Installer"
    echo ""
    echo "Usage: ./install-custom.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --project        Install to current project (.claude/skills/)"
    echo "  --path PATH      Install to custom path"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "The installer will:"
    echo "  1. Check if solana-dev-skill is already installed"
    echo "  2. If not found, offer to install it"
    echo "  3. Install solana-mev-skill addon"
    echo ""
}

find_core_skill() {
    local locations=(
        "$PERSONAL_SKILLS_DIR/$CORE_SKILL_NAME"
        "$PROJECT_SKILLS_DIR/$CORE_SKILL_NAME"
        "$HOME/.claude/$CORE_SKILL_NAME"
    )

    for loc in "${locations[@]}"; do
        if [ -d "$loc" ] && [ -f "$loc/SKILL.md" ]; then
            CORE_SKILL_FOUND="true"
            CORE_SKILL_LOCATION="$loc"
            return 0
        fi
    done

    CORE_SKILL_FOUND="false"
    return 1
}

prompt_install_location() {
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}Select Installation Location${NC}                               ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${WHITE}[1]${NC} ${GREEN}Personal skills${NC} (~/.claude/skills/)"
    echo -e "      ${YELLOW}Available to all projects${NC}"
    echo ""
    echo -e "  ${WHITE}[2]${NC} ${GREEN}Current project${NC} (./.claude/skills/)"
    echo -e "      ${YELLOW}Only for this project${NC}"
    echo ""
    echo -e "  ${WHITE}[3]${NC} ${RED}Cancel${NC}"
    echo ""

    read -p "Select option [1-3]: " choice

    case $choice in
        1)
            INSTALL_BASE="$PERSONAL_SKILLS_DIR"
            ;;
        2)
            INSTALL_BASE="$PROJECT_SKILLS_DIR"
            ;;
        3)
            echo -e "${YELLOW}Installation cancelled${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Installation cancelled${NC}"
            exit 1
            ;;
    esac

    MEV_INSTALL_PATH="$INSTALL_BASE/$MEV_SKILL_NAME"
    CORE_INSTALL_PATH="$INSTALL_BASE/$CORE_SKILL_NAME"
}

prompt_install_core_skill() {
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}Core Skill Required${NC}                                        ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${YELLOW}solana-dev-skill${NC} was not found."
    echo -e "  The MEV skill depends on it for:"
    echo -e "    ${BLUE}•${NC} Transaction building patterns"
    echo -e "    ${BLUE}•${NC} Anchor/Pinocchio program development"
    echo -e "    ${BLUE}•${NC} Security checklists"
    echo -e "    ${BLUE}•${NC} Testing (LiteSVM, Mollusk)"
    echo ""
    echo -e "  ${WHITE}[1]${NC} ${GREEN}Install both${NC} (solana-dev + solana-mev)"
    echo -e "  ${WHITE}[2]${NC} ${YELLOW}Install MEV skill only${NC} (I'll install core separately)"
    echo -e "  ${WHITE}[3]${NC} ${RED}Cancel${NC}"
    echo ""

    read -p "Select option [1-3]: " choice

    case $choice in
        1)
            install_core_skill
            ;;
        2)
            echo -e "${YELLOW}Warning:${NC} MEV skill will have broken references to core skill"
            echo -e "Install solana-dev-skill to: ${BLUE}$CORE_INSTALL_PATH${NC}"
            ;;
        3)
            echo -e "${YELLOW}Installation cancelled${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Installation cancelled${NC}"
            exit 1
            ;;
    esac
}

install_core_skill() {
    echo ""
    echo -e "${CYAN}━━━ Installing Core Solana Dev Skill ━━━${NC}"

    mkdir -p "$CORE_INSTALL_PATH"

    echo -e "Cloning from ${BLUE}github.com/solana-foundation/solana-dev-skill${NC}..."

    local temp_dir=$(mktemp -d)
    if git clone --depth 1 https://github.com/solana-foundation/solana-dev-skill.git "$temp_dir" 2>/dev/null; then
        cp -r "$temp_dir/skill/"* "$CORE_INSTALL_PATH/"
        rm -rf "$temp_dir"
        echo -e "${GREEN}✓${NC} Installed solana-dev-skill to: $CORE_INSTALL_PATH"
        CORE_SKILL_FOUND="true"
        CORE_SKILL_LOCATION="$CORE_INSTALL_PATH"
    else
        rm -rf "$temp_dir"
        echo -e "${RED}Error:${NC} Failed to clone solana-dev-skill"
        echo -e "${YELLOW}You can install it manually:${NC}"
        echo -e "  git clone https://github.com/solana-foundation/solana-dev-skill"
        echo -e "  cp -r solana-dev-skill/skill/* $CORE_INSTALL_PATH/"
        return 1
    fi
}

install_mev_skill() {
    echo ""
    echo -e "${CYAN}━━━ Installing Solana MEV Skill ━━━${NC}"

    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "${RED}Error:${NC} Source directory '$SOURCE_DIR' not found"
        exit 1
    fi

    if [ -d "$MEV_INSTALL_PATH" ]; then
        echo -e "${YELLOW}Warning:${NC} '$MEV_INSTALL_PATH' already exists"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Skipping MEV skill installation${NC}"
            return 0
        fi
        rm -rf "$MEV_INSTALL_PATH"
    fi

    mkdir -p "$MEV_INSTALL_PATH"

    for item in "$SOURCE_DIR"/*; do
        local basename=$(basename "$item")
        if [ "$basename" != "solana-dev-skill" ]; then
            cp -r "$item" "$MEV_INSTALL_PATH/"
        fi
    done

    echo -e "${GREEN}✓${NC} Installed solana-mev-skill to: $MEV_INSTALL_PATH"

    echo ""
    echo -e "${WHITE}Installed MEV skill files:${NC}"
    find "$MEV_INSTALL_PATH" -type f -name "*.md" | sort | while read -r file; do
        echo -e "  ${BLUE}•${NC} $(basename "$file")"
    done
}

install_claude_md() {
    local claude_md_source="$SCRIPT_DIR/CLAUDE.md"

    echo ""
    echo -e "${CYAN}━━━ CLAUDE.md Configuration ━━━${NC}"
    echo ""
    echo -e "  ${WHITE}CLAUDE.md${NC} provides project-level Claude configuration."
    echo -e "  It includes stack decisions, workflow rules, and skill references."
    echo ""
    echo -e "  ${WHITE}[1]${NC} Copy to ${GREEN}current directory${NC} (.)"
    echo -e "  ${WHITE}[2]${NC} Copy to ${GREEN}home .claude${NC} (~/.claude/)"
    echo -e "  ${WHITE}[3]${NC} ${YELLOW}Skip${NC} CLAUDE.md installation"
    echo ""

    read -p "Select option [1-3]: " claude_choice

    case $claude_choice in
        1)
            if [ -f "./CLAUDE.md" ]; then
                echo -e "${YELLOW}Warning:${NC} CLAUDE.md already exists in current directory"
                read -p "Overwrite? (y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Skipping CLAUDE.md${NC}"
                    return 0
                fi
            fi
            cp "$claude_md_source" "./CLAUDE.md"
            echo -e "${GREEN}✓${NC} Copied CLAUDE.md to current directory"
            ;;
        2)
            mkdir -p "$HOME/.claude"
            if [ -f "$HOME/.claude/CLAUDE.md" ]; then
                echo -e "${YELLOW}Warning:${NC} CLAUDE.md already exists at ~/.claude/"
                read -p "Overwrite? (y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Skipping CLAUDE.md${NC}"
                    return 0
                fi
            fi
            cp "$claude_md_source" "$HOME/.claude/CLAUDE.md"
            echo -e "${GREEN}✓${NC} Copied CLAUDE.md to ~/.claude/"
            ;;
        3)
            echo -e "${YELLOW}Skipping CLAUDE.md installation${NC}"
            ;;
        *)
            echo -e "${YELLOW}Invalid option, skipping CLAUDE.md${NC}"
            ;;
    esac
}

print_success() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${WHITE}Installation Complete!${NC}                                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                               ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ -d "$MEV_INSTALL_PATH" ]; then
        echo -e "${WHITE}MEV Skill:${NC} $MEV_INSTALL_PATH"
    fi

    if [ "$CORE_SKILL_FOUND" = "true" ]; then
        echo -e "${WHITE}Core Skill:${NC} $CORE_SKILL_LOCATION"
    fi

    echo ""
    echo -e "${CYAN}Try asking Claude about:${NC}"
    echo -e "  ${BLUE}•${NC} \"Explain the MEV landscape on Solana\""
    echo -e "  ${BLUE}•${NC} \"Build a Jito bundle for arbitrage\""
    echo -e "  ${BLUE}•${NC} \"Monitor Kamino for liquidation opportunities\""
    echo -e "  ${BLUE}•${NC} \"Analyze this transaction for MEV risk\""
    echo ""

    if [ "$CORE_SKILL_FOUND" = "true" ]; then
        echo -e "  ${BLUE}•${NC} \"Create an Anchor program for my MEV strategy\""
        echo -e "  ${BLUE}•${NC} \"Set up LiteSVM tests for my searcher\""
    fi

    echo ""
    echo -e "${YELLOW}Optional:${NC} Copy agents and commands to your project:"
    echo -e "  cp -r $SCRIPT_DIR/agents /path/to/project/.claude/agents/"
    echo -e "  cp -r $SCRIPT_DIR/commands /path/to/project/.claude/commands/"
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --project)
            INSTALL_BASE="$PROJECT_SKILLS_DIR"
            shift
            ;;
        --path)
            INSTALL_BASE="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_banner

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error:${NC} Source directory '$SOURCE_DIR' not found"
    exit 1
fi

if [ ! -f "$SOURCE_DIR/SKILL.md" ]; then
    echo -e "${RED}Error:${NC} SKILL.md not found in '$SOURCE_DIR'"
    exit 1
fi

if [ -z "$INSTALL_BASE" ]; then
    prompt_install_location
else
    MEV_INSTALL_PATH="$INSTALL_BASE/$MEV_SKILL_NAME"
    CORE_INSTALL_PATH="$INSTALL_BASE/$CORE_SKILL_NAME"
fi

echo ""
echo -e "${CYAN}Checking for existing solana-dev-skill...${NC}"

if find_core_skill; then
    echo -e "${GREEN}✓${NC} Found solana-dev-skill at: ${BLUE}$CORE_SKILL_LOCATION${NC}"
else
    echo -e "${YELLOW}✗${NC} solana-dev-skill not found"
    prompt_install_core_skill
fi

install_mev_skill

install_claude_md

print_success
