import os

workflow_dir = r'c:\Users\JeffreyLeBlanc\OneDrive - Stratovate Solutions LLC\Development\Misc Scripts\Powershell\.github\workflows'

# Comprehensive Unicode to ASCII replacements
unicode_replacements = {
    '✅': '[OK]',
    '❌': '[ERROR]',
    '⚠': '[WARNING]', 
    '🎯': '[TARGET]',
    '📊': '[CHART]',
    '📍': '[PIN]',
    '🔧': '[CONFIG]',
    '🚀': '[DEPLOY]',
    '🛡️': '[SHIELD]',
    '🔍': '[SEARCH]',
    '📋': '[LIST]',
    '🔐': '[LOCK]',
    '🏗️': '[BUILD]',
    '📝': '[NOTE]',
    '🎉': '[SUCCESS]',
    '🔄': '[REFRESH]',
    '💾': '[SAVE]',
    '🗂️': '[FILES]',
    '📈': '[GRAPH]',
    '🌟': '[STAR]',
    '⭐': '[STAR]',
    '💡': '[IDEA]',
    '🎨': '[ART]',
    '🚨': '[ALERT]',
    '🔬': '[TEST]',
    '🎪': '[EVENT]',
    '📦': '[PACKAGE]',
    '🏷️': '[TAG]',
    '🌍': '[GLOBAL]',
    '🔗': '[LINK]',
    '📱': '[MOBILE]',
    '💻': '[COMPUTER]',
    '⚡': '[FAST]',
    '🎭': '[MASK]',
    '🎲': '[RANDOM]',
    '📢': '[ANNOUNCE]',
    '📣': '[BROADCAST]',
    '🎁': '[GIFT]',
    '🎳': '[GAME]',
    '⚙️': '[GEAR]',
    '💫': '[SPARK]',
    '🌈': '[RAINBOW]',
    '🏁': '[FINISH]',
    # Smart quotes and dashes
    ''': "'",
    ''': "'",
    '"': '"',
    '"': '"',
    '—': '--',
    '–': '-'
}

for filename in os.listdir(workflow_dir):
    if filename.endswith(('.yml', '.yaml')):
        filepath = os.path.join(workflow_dir, filename)
        print(f'Processing {filename}...')
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Replace all Unicode characters
        for unicode_char, ascii_replacement in unicode_replacements.items():
            content = content.replace(unicode_char, ascii_replacement)
        
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'  - Updated {filename} with ASCII replacements')
        else:
            print(f'  - No changes needed for {filename}')

print('Completed comprehensive Unicode cleanup')
