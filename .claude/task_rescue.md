CRITICAL: fix all compilation errors in home_page.dart.
Read the full file. There are broken parentheses from a buggy sed command. 

Known issues:
- Line 376: Too many positional arguments
- Line 395: Missing identifier  
- Line 408: Expected ')'

Fix ALL syntax errors. Do NOT restructure the file — just fix brackets/parentheses/commas.
Run `flutter analyze` to verify 0 errors after fixing.
