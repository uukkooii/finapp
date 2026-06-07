FINISH AND CLEAN UP. Two goals:

## 1. CUTE-IFY REMAINING 3 PAGES
Apply the same cute theme to: cashflow_page.dart, credit_page.dart, search_page.dart
- Use the new colors from constants: goldColor/pink #FF8FAB, cardColor #2A2540, bgColor #1E1B2E
- Round corners: 24px for cards, 16px for inner elements
- Pill/capsule buttons (borderRadius 50)
- Add emoji icons wherever helpful
- Gradient card backgrounds instead of flat

## 2. SLIM DOWN BLOATED FILES
These grew too much. Remove unnecessary fluff while keeping functionality:

home_page.dart (930 lines / 33KB): 
- Remove redundant comment blocks (// ── Title ──)
- Collapse simple builder patterns that don't need separate methods
- Remove unused imports or variables

goals_page.dart (28KB):
- Same cleanup

add_transaction_page.dart (18KB):
- Same cleanup

## TARGET: Keep under 25KB per file, under 600 lines each.

## RULES
- Keep all existing functionality
- Keep cute visuals
- After changes: flutter build apk --debug, fix errors until BUILD SUCCESSFUL
