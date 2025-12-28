# PVTRO Project Brief

## Overview
PVTRO (PathVerse Translation Orchestrator) is a **CLI helper tool** for multi-package Flutter apps using slang 4.11+.

**Key Insight**: Slang 4.11+ handles locale sync natively. PVTRO assists by automating wrapper generation and validating configurations.

## Role: Helper Tool, Not Solution
Slang has made massive improvements to multi-package sync. PVTRO:
- ✅ Assists with tedious wrapper nesting
- ✅ Validates package configurations (planned)
- ✅ Bridges web sources to local builds (planned)
- ❌ Does NOT replace slang functionality

## Primary Objectives
1. **Package Discovery**: Scan for slang-enabled packages
2. **Wrapper Generation**: Automate TranslationProvider nesting
3. **Validation**: Check version compatibility and locale matching
4. **Web Integration**: Import translations from web sources (future)

## What We Generate
- Nested `TranslationProvider` wrapper function

## What We DON'T Generate
- UnifiedLanguage enum (slang handles)
- Switch-case locale parsers (slang handles)
- LocaleCubit (use slang directly)

## Target Users
- Flutter developers using slang 4.11+ across multiple packages
- Monorepo projects with slang-enabled subpackages

## Success Criteria
- `dart run pvtro` generates clean wrapper
- Assists without getting in the way
- Future: seamless web source integration
